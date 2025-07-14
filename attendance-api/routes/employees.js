const express = require('express');
const multer  = require('multer');
const path    = require('path');
const pool    = require('../db');
const router  = express.Router();

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, process.env.UPLOAD_DIR),
  filename:    (_, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage });

router.post('/upload-face/:employeeId', upload.single('face'), async (req, res) => {
  const url = `${req.protocol}://${req.get('host')}/images/${req.file.filename}`;
  try {
    await pool.query(
      'UPDATE employees SET face_image_url = ? WHERE employeeID = ?',
      [url, req.params.employeeId]
    );
    res.json({ url });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});
router.get('/:employeeId', async (req, res) => {
  const { employeeId } = req.params;
  try {
    const [rows] = await pool.query(
      'SELECT * FROM employees WHERE employeeId = ?',
      [employeeId]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Employee not found' });
    }
    res.json(rows[0]);
  } catch (e) {
    console.error('GET /employees/:employeeId error:', e);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
