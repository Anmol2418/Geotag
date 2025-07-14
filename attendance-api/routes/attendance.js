const express = require('express');
const multer  = require('multer');
const path    = require('path');
const fs      = require('fs');
const pool    = require('../db');  // Your MySQL pool connection
const router  = express.Router();

// Upload directory for face images
const uploadDir = process.env.UPLOAD_DIR || path.join(__dirname, '..', 'uploads', 'faces');
fs.mkdirSync(uploadDir, { recursive: true });

// Multer storage config for face uploads
const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadDir),
  filename: (_, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage });

// Upload face image endpoint
router.post('/upload-face/:employeeId', upload.single('face'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No face image uploaded' });
  }
  const url = `${req.protocol}://${req.get('host')}/uploads/faces/${req.file.filename}`;
  try {
    await pool.query(
      'UPDATE employees SET face_image_url = ? WHERE employee_id = ?',
      [url, req.params.employeeId]
    );
    res.json({ url });
  } catch (e) {
    console.error('DB update error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Clock In API
router.post('/clock-in', async (req, res) => {
  const { employeeId } = req.body;
  const now = new Date();

  if (!employeeId) return res.status(400).json({ error: 'Missing employeeId' });

  try {
    // Check if already clocked in today without clocking out
    const [existingRows] = await pool.query(
      'SELECT * FROM attendance_logs WHERE employee_id = ? AND date = CURDATE() AND clock_out IS NULL',
      [employeeId]
    );

    if (existingRows.length > 0) {
      return res.status(400).json({ error: 'Already clocked in today' });
    }

    // Insert new attendance log
    await pool.query(
      'INSERT INTO attendance_logs (employee_id, date, clock_in) VALUES (?, CURDATE(), ?)',
      [employeeId, now]
    );

    res.json({ message: 'Clock-in recorded', clockInTime: now });
  } catch (error) {
    console.error('Clock-in error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Clock Out API
router.post('/clock-out', async (req, res) => {
  const { employeeId } = req.body;
  const now = new Date();

  if (!employeeId) return res.status(400).json({ error: 'Missing employeeId' });

  try {
    const [rows] = await pool.query(
      'SELECT * FROM attendance_logs WHERE employee_id = ? AND DATE(`date`) = CURDATE() AND clock_out IS NULL',
      [employeeId]
    );

    if (rows.length === 0) {
      return res.status(400).json({ error: 'No active clock-in found for today' });
    }

    const record = rows[0];
    const clockInTime = new Date(record.clock_in);
    let durationMinutes = 0;

    if (isNaN(clockInTime.getTime())) {
      console.warn('Warning: clock_in time is invalid or missing');
      durationMinutes = 0; // or null if your DB allows it
    } else {
      const durationMs = now - clockInTime;
      durationMinutes = Math.floor(durationMs / 60000);
    }

    await pool.query(
      'UPDATE attendance_logs SET clock_out = ?, duration = ? WHERE id = ?',
      [now, durationMinutes, record.id]
    );

    res.json({ message: 'Clock-out recorded', clockOutTime: now, durationMinutes });
  } catch (error) {
    console.error('Clock-out error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});


module.exports = router;
