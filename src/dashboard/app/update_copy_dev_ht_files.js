// ==============================================================
// copies .htaccess and .htpasswd to op build DIST directory
//
// expects files in ../_create_htaccess_files_dev/ :
//   .htaccess
//   .htpasswd
//
// ==============================================================

const fs = require('fs');

// File destination.txt will be created or overwritten by default.
fs.copyFile('../_create/htaccess_files_dev/.htaccess', 'dist/app/browser/.htaccess', (err) => {
  if (err) throw err;
  console.log('.htaccess was copied to DIST');
});

fs.copyFile('../_create/htaccess_files_dev/.htpasswd', 'dist/app/browser/.htpasswd', (err) => {
  if (err) throw err;
  console.log('.htpasswd was copied to DIST');
});
