const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const pool = require('../db');

const router = express.Router();

// Setup Multer to save face image in uploads/faces
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, '..', 'uploads', 'faces');
    fs.mkdirSync(dir, { recursive: true }); // ensure folder exists
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `${req.body.employeeId}${ext}`);
  }
});

const upload = multer({ storage });

// ─────────── REGISTER ───────────
router.post('/register', upload.single('face'), async (req, res) => {
  try {
    // Destructure AFTER multer processes the request
    const { employeeId, name, email, password } = req.body;
    const file = req.file;

    if (!employeeId || !name || !email || !password || !file) {
      return res.status(400).json({ error: 'Missing required fields or image.' });
    }

    const hash = await bcrypt.hash(password, 10);
    const faceImageUrl = `/uploads/faces/${file.filename}`;

    const [result] = await pool.query(
      'INSERT INTO employees (employeeId, name, email, password, face_image_url) VALUES (?, ?, ?, ?, ?)',
      [employeeId, name, email, hash, faceImageUrl]
    );

    if (result.affectedRows === 1) {
      return res.status(201).json({ msg: 'registered' });
    } else {
      return res.status(400).json({ error: 'Insert failed' });
    }
  } catch (e) {
    console.error('Register error:', e);
    res.status(500).json({ error: e.message });
  }
});

// ─────────── LOGIN ───────────
router.post('/login', async (req, res) => {
  const { employeeId, password } = req.body;
  try {
    const [rows] = await pool.query(
      'SELECT * FROM employees WHERE employeeId = ?',
      [employeeId]
    );

    if (rows.length === 0) return res.status(401).json({ error: 'no user' });

    const user = rows[0];
    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ error: 'bad pass' });

    const token = jwt.sign({ employeeId }, process.env.JWT_SECRET, { expiresIn: '1d' });

    res.json({
      token,
      employee: {
        employee_id: user.employeeId,
        name: user.name,
        email: user.email,
        face_image_url: user.face_image_url || null,
      }
    });
  } catch (e) {
    console.error('Login error:', e);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
