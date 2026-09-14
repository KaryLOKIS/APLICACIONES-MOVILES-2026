const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const dotenv = require('dotenv');
const { v4: uuidv4 } = require('uuid');
const {
  body,
  validationResult,
} = require('express-validator');

dotenv.config();

const app = express();

// ==========================================
// CONFIGURACIÓN
// ==========================================

const PORT = Number(process.env.PORT) || 3000;

const ACCESS_TOKEN_MINUTES =
  Number(process.env.ACCESS_TOKEN_MINUTES) || 2;

const REFRESH_TOKEN_DAYS =
  Number(process.env.REFRESH_TOKEN_DAYS) || 7;

const JWT_ACCESS_SECRET = process.env.JWT_ACCESS_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;

if (!JWT_ACCESS_SECRET || !JWT_REFRESH_SECRET) {
  console.error(
    'PETCARE ERROR: No existen las claves JWT en el archivo .env'
  );

  process.exit(1);
}

// ==========================================
// MIDDLEWARE
// ==========================================

app.use(cors());
app.use(express.json());

// ==========================================
// SQLITE
// ==========================================

const DB_PATH = './petcare.db';

const db = new sqlite3.Database(DB_PATH, (error) => {
  if (error) {
    console.error(
      'PETCARE ERROR: No se pudo abrir SQLite:',
      error.message
    );
    return;
  }

  console.log('PETCARE: Base de datos SQLite conectada');
});

// ==========================================
// FUNCIONES AUXILIARES SQLITE
// ==========================================

function dbRun(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (error) {
      if (error) {
        reject(error);
        return;
      }

      resolve({
        lastID: this.lastID,
        changes: this.changes,
      });
    });
  });
}

function dbGet(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (error, row) => {
      if (error) {
        reject(error);
        return;
      }

      resolve(row);
    });
  });
}

function dbAll(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (error, rows) => {
      if (error) {
        reject(error);
        return;
      }

      resolve(rows);
    });
  });
}

// ==========================================
// CREACIÓN DE TABLAS
// ==========================================

db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      nombre TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  `, (error) => {
    if (error) {
      console.error(
        'PETCARE ERROR creando users:',
        error.message
      );
    } else {
      console.log('PETCARE: Tabla users lista');
    }
  });

  db.run(`
    CREATE TABLE IF NOT EXISTS pets (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      especie TEXT NOT NULL,
      raza TEXT NOT NULL,
      edad INTEGER NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  `, (error) => {
    if (error) {
      console.error(
        'PETCARE ERROR creando pets:',
        error.message
      );
    } else {
      console.log('PETCARE: Tabla pets lista');
    }
  });
});

// ==========================================
// CREACIÓN DE TOKENS
// ==========================================

function crearAccessToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      email: user.email,
      type: 'access',
    },
    JWT_ACCESS_SECRET,
    {
      expiresIn: `${ACCESS_TOKEN_MINUTES}m`,
    }
  );
}

function crearRefreshToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      email: user.email,
      type: 'refresh',
    },
    JWT_REFRESH_SECRET,
    {
      expiresIn: `${REFRESH_TOKEN_DAYS}d`,
    }
  );
}

// ==========================================
// VALIDACIÓN DE ERRORES 422
// ==========================================

function validarPeticion(req, res, next) {
  const errores = validationResult(req);

  if (!errores.isEmpty()) {
    return res.status(422).json({
      error: 'VALIDATION_ERROR',
      mensaje: 'Existen errores en los campos enviados.',
      campos: errores.array().map((error) => ({
        campo: error.path,
        mensaje: error.msg,
      })),
    });
  }

  next();
}

// ==========================================
// MIDDLEWARE DE AUTENTICACIÓN
// ==========================================

function autenticarToken(req, res, next) {
  const authorization = req.headers.authorization;

  if (!authorization) {
    return res.status(401).json({
      error: 'UNAUTHORIZED',
      mensaje: 'No se proporcionó un token de acceso.',
    });
  }

  const partes = authorization.split(' ');

  if (partes.length !== 2 || partes[0] !== 'Bearer') {
    return res.status(401).json({
      error: 'UNAUTHORIZED',
      mensaje: 'Formato de autorización inválido.',
    });
  }

  const token = partes[1];

  try {
    const payload = jwt.verify(
      token,
      JWT_ACCESS_SECRET
    );

    if (payload.type !== 'access') {
      return res.status(401).json({
        error: 'UNAUTHORIZED',
        mensaje: 'El token no es un token de acceso válido.',
      });
    }

    req.user = {
      id: payload.sub,
      email: payload.email,
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'TOKEN_EXPIRED',
        mensaje: 'El token de acceso ha expirado.',
      });
    }

    return res.status(401).json({
      error: 'UNAUTHORIZED',
      mensaje: 'El token de acceso no es válido.',
    });
  }
}

// ==========================================
// RUTA PRINCIPAL
// ==========================================

app.get('/', (req, res) => {
  res.json({
    mensaje: 'Backend de PetCare funcionando correctamente',
    estado: 'OK',
  });
});

// ==========================================
// HEALTH CHECK
// ==========================================

app.get('/api/health', (req, res) => {
  res.json({
    servicio: 'PetCare API',
    estado: 'activo',
    baseDatos: 'SQLite',
  });
});

// ==========================================
// REGISTRO
// ==========================================

app.post(
  '/api/auth/register',

  [
    body('nombre')
      .trim()
      .notEmpty()
      .withMessage('El nombre es obligatorio.')
      .isLength({ min: 2, max: 100 })
      .withMessage(
        'El nombre debe tener entre 2 y 100 caracteres.'
      ),

    body('email')
      .trim()
      .isEmail()
      .withMessage('El correo electrónico no es válido.')
      .normalizeEmail(),

    body('password')
      .isLength({ min: 6 })
      .withMessage(
        'La contraseña debe tener al menos 6 caracteres.'
      ),
  ],

  validarPeticion,

  async (req, res) => {
    try {
      const {
        nombre,
        email,
        password,
      } = req.body;

      const usuarioExistente = await dbGet(
        `
        SELECT id
        FROM users
        WHERE email = ?
        `,
        [email]
      );

      if (usuarioExistente) {
        return res.status(409).json({
          error: 'EMAIL_EXISTS',
          mensaje: 'El correo electrónico ya está registrado.',
        });
      }

      const passwordHash = await bcrypt.hash(
        password,
        12
      );

      const userId = uuidv4();
      const createdAt = new Date().toISOString();

      await dbRun(
        `
        INSERT INTO users (
          id,
          nombre,
          email,
          password_hash,
          created_at
        )
        VALUES (?, ?, ?, ?, ?)
        `,
        [
          userId,
          nombre,
          email,
          passwordHash,
          createdAt,
        ]
      );

      const user = {
        id: userId,
        nombre,
        email,
      };

      const accessToken = crearAccessToken(user);
      const refreshToken = crearRefreshToken(user);

      console.log(
        `PETCARE: Usuario registrado ${email}`
      );

      return res.status(201).json({
        mensaje: 'Usuario registrado correctamente.',
        usuario: user,
        access_token: accessToken,
        refresh_token: refreshToken,
      });
    } catch (error) {
      console.error(
        'PETCARE ERROR registro:',
        error.message
      );

      return res.status(500).json({
        error: 'SERVER_ERROR',
        mensaje: 'No fue posible registrar el usuario.',
      });
    }
  }
);

// ==========================================
// LOGIN
// ==========================================

app.post(
  '/api/auth/login',

  [
    body('email')
      .trim()
      .isEmail()
      .withMessage('El correo electrónico no es válido.')
      .normalizeEmail(),

    body('password')
      .notEmpty()
      .withMessage('La contraseña es obligatoria.'),
  ],

  validarPeticion,

  async (req, res) => {
    try {
      const {
        email,
        password,
      } = req.body;

      const user = await dbGet(
        `
        SELECT
          id,
          nombre,
          email,
          password_hash,
          created_at
        FROM users
        WHERE email = ?
        `,
        [email]
      );

      if (!user) {
        return res.status(401).json({
          error: 'INVALID_CREDENTIALS',
          mensaje: 'Correo o contraseña incorrectos.',
        });
      }

      const passwordCorrecta =
        await bcrypt.compare(
          password,
          user.password_hash
        );

      if (!passwordCorrecta) {
        return res.status(401).json({
          error: 'INVALID_CREDENTIALS',
          mensaje: 'Correo o contraseña incorrectos.',
        });
      }

      const userPublic = {
        id: user.id,
        nombre: user.nombre,
        email: user.email,
      };

      const accessToken =
        crearAccessToken(userPublic);

      const refreshToken =
        crearRefreshToken(userPublic);

      console.log(
        `PETCARE: Login correcto ${email}`
      );

      return res.json({
        mensaje: 'Inicio de sesión correcto.',
        usuario: userPublic,
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_in: ACCESS_TOKEN_MINUTES * 60,
      });
    } catch (error) {
      console.error(
        'PETCARE ERROR login:',
        error.message
      );

      return res.status(500).json({
        error: 'SERVER_ERROR',
        mensaje: 'No fue posible iniciar sesión.',
      });
    }
  }
);

// ==========================================
// RENOVAR TOKEN
// ==========================================

app.post(
  '/api/auth/refresh',

  [
    body('refresh_token')
      .notEmpty()
      .withMessage(
        'El refresh token es obligatorio.'
      ),
  ],

  validarPeticion,

  async (req, res) => {
    try {
      const {
        refresh_token: refreshToken,
      } = req.body;

      let payload;

      try {
        payload = jwt.verify(
          refreshToken,
          JWT_REFRESH_SECRET
        );
      } catch (error) {
        return res.status(401).json({
          error: 'REFRESH_TOKEN_INVALID',
          mensaje: 'El refresh token no es válido o ha expirado.',
        });
      }

      if (payload.type !== 'refresh') {
        return res.status(401).json({
          error: 'REFRESH_TOKEN_INVALID',
          mensaje: 'El token enviado no es un refresh token.',
        });
      }

      const user = await dbGet(
        `
        SELECT
          id,
          nombre,
          email
        FROM users
        WHERE id = ?
        `,
        [payload.sub]
      );

      if (!user) {
        return res.status(401).json({
          error: 'USER_NOT_FOUND',
          mensaje: 'El usuario ya no existe.',
        });
      }

      const newAccessToken =
        crearAccessToken(user);

      const newRefreshToken =
        crearRefreshToken(user);

      console.log(
        `PETCARE: Token renovado ${user.email}`
      );

      return res.json({
        mensaje: 'Token renovado correctamente.',
        access_token: newAccessToken,
        refresh_token: newRefreshToken,
        expires_in: ACCESS_TOKEN_MINUTES * 60,
      });
    } catch (error) {
      console.error(
        'PETCARE ERROR refresh:',
        error.message
      );

      return res.status(500).json({
        error: 'SERVER_ERROR',
        mensaje: 'No fue posible renovar el token.',
      });
    }
  }
);

// ==========================================
// DATOS DEL USUARIO ACTUAL
// ==========================================

app.get(
  '/api/auth/me',
  autenticarToken,
  async (req, res) => {
    try {
      const user = await dbGet(
        `
        SELECT
          id,
          nombre,
          email,
          created_at
        FROM users
        WHERE id = ?
        `,
        [req.user.id]
      );

      if (!user) {
        return res.status(404).json({
          error: 'USER_NOT_FOUND',
          mensaje: 'Usuario no encontrado.',
        });
      }

      return res.json({
        usuario: user,
      });
    } catch (error) {
      console.error(
        'PETCARE ERROR /me:',
        error.message
      );

      return res.status(500).json({
        error: 'SERVER_ERROR',
        mensaje: 'No fue posible obtener el usuario.',
      });
    }
  }
);

// ==========================================
// LISTAR MASCOTAS
// ==========================================

app.get(
  '/api/pets',
  autenticarToken,
  async (req, res) => {
    try {
      const pets = await dbAll(
        `
        SELECT
          id,
          nombre,
          especie,
          raza,
          edad,
          updated_at
        FROM pets
        WHERE user_id = ?
        ORDER BY nombre ASC
        `,
        [req.user.id]
      );

      return res.json({
        datos: pets,
        total: pets.length,
      });
    } catch (error) {
      console.error(
        'PETCARE ERROR GET /api/pets:',
        error.message
      );

      return res.status(500).json({
        error: 'SERVER_ERROR',
        mensaje: 'No fue posible obtener las mascotas.',
      });
    }
  }
);

// ==========================================
// CREAR MASCOTA
// ==========================================

app.post(
  '/api/pets',

  autenticarToken,

  [
    body('nombre')
      .trim()
      .notEmpty()
      .withMessage('El nombre de la mascota es obligatorio.')
      .isLength({ max: 100 })
      .withMessage(
        'El nombre de la mascota no puede superar 100 caracteres.'
      ),

    body('especie')
      .trim()
      .notEmpty()
      .withMessage('La especie es obligatoria.'),

    body('raza')
      .trim()
      .notEmpty()
      .withMessage('La raza es obligatoria.'),

    body('edad')
      .isInt({ min: 0, max: 100 })
      .withMessage(
        'La edad debe ser un número entero entre 0 y 100.'
      ),
  ],

  validarPeticion,

  async (req, res) => {
    try {
      const {
        nombre,
        especie,
        raza,
        edad,
      } = req.body;

      const petId = uuidv4();
      const updatedAt = new Date().toISOString();

      await dbRun(
        `
        INSERT INTO pets (
          id,
          user_id,
          nombre,
          especie,
          raza,
          edad,
          updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
        `,
        [
          petId,
          req.user.id,
          nombre,
          especie,
          raza,
          Number(edad),
          updatedAt,
        ]
      );

      const pet = await dbGet(
        `
        SELECT
          id,
          nombre,
          especie,
          raza,
          edad,
          updated_at
        FROM pets
        WHERE id = ?
        `,
        [petId]
      );

      console.log(
        `PETCARE: Mascota creada ${nombre}`
      );

      return res.status(201).json({
        mensaje: 'Mascota creada correctamente.',
        datos: pet,
      });
    } catch (error) {
      console.error(
        'PETCARE ERROR POST /api/pets:',
        error.message
      );

      return res.status(500).json({
        error: 'SERVER_ERROR',
        mensaje: 'No fue posible crear la mascota.',
      });
    }
  }
);

// ==========================================
// ELIMINAR MASCOTA
// ==========================================

app.delete(
  '/api/pets/:id',
  autenticarToken,
  async (req, res) => {
    try {
      const resultado = await dbRun(
        `
        DELETE FROM pets
        WHERE id = ?
        AND user_id = ?
        `,
        [
          req.params.id,
          req.user.id,
        ]
      );

      if (resultado.changes === 0) {
        return res.status(404).json({
          error: 'PET_NOT_FOUND',
          mensaje: 'Mascota no encontrada.',
        });
      }

      return res.json({
        mensaje: 'Mascota eliminada correctamente.',
      });
    } catch (error) {
      console.error(
        'PETCARE ERROR DELETE /api/pets:',
        error.message
      );

      return res.status(500).json({
        error: 'SERVER_ERROR',
        mensaje: 'No fue posible eliminar la mascota.',
      });
    }
  }
);

// ==========================================
// MANEJO DE ERRORES GENERALES
// ==========================================

app.use((error, req, res, next) => {
  console.error(
    'PETCARE ERROR GENERAL:',
    error.message
  );

  res.status(500).json({
    error: 'SERVER_ERROR',
    mensaje: 'Ocurrió un error inesperado.',
  });
});

// ==========================================
// INICIAR SERVIDOR
// ==========================================

app.listen(
  PORT,
  '0.0.0.0',
  () => {
    console.log('==========================================');
    console.log('      PETCARE BACKEND INICIADO');
    console.log('==========================================');
    console.log(
      `Servidor ejecutándose en el puerto ${PORT}`
    );
    console.log(
      'URL local: http://localhost:3000'
    );
    console.log(
      'URL Android Emulator: http://10.0.2.2:3000'
    );
    console.log(
      `Access token: ${ACCESS_TOKEN_MINUTES} minutos`
    );
    console.log(
      `Refresh token: ${REFRESH_TOKEN_DAYS} días`
    );
    console.log('==========================================');
  }
);