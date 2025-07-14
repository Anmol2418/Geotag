require('dotenv').config();
const pool = require('./db');        // your existing db.js file exporting mysql pool
const bcrypt = require('bcrypt');

async function hashExistingPasswords() {
  try {
    // Get all users
    const [users] = await pool.query('SELECT employeeId, password FROM employees');

    for (const user of users) {
      // Skip if password already hashed (bcrypt hashes start with $2)
      if (!user.password.startsWith('$2')) {
        const hashed = await bcrypt.hash(user.password, 10);
        await pool.query(
          'UPDATE employees SET password = ? WHERE employeeId = ?',
          [hashed, user.employeeId]
        );
        console.log(`Password hashed for user ${user.employeeId}`);
      } else {
        console.log(`User ${user.employeeId} already has hashed password`);
      }
    }

    console.log('Password update completed.');
    process.exit(0);
  } catch (error) {
    console.error('Error during password hashing:', error);
    process.exit(1);
  }
}

hashExistingPasswords();
