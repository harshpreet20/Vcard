const { createHash, createSign } = require('crypto');
const { readFileSync } = require('fs');
const { join } = require('path');

/*
 * Vercel Serverless Function — Generates a signed .pkpass for Apple Wallet
 *
 * SETUP REQUIRED (one-time):
 * 1. In Apple Developer > Certificates, Identifiers & Profiles:
 *    - Create a Pass Type ID (e.g., pass.com.hotbotstudios.vcard)
 *    - Generate a certificate for it, download the .cer
 *    - Export as .p12 from Keychain, then convert:
 *      openssl pkcs12 -in cert.p12 -clcerts -nokeys -out pass-cert.pem
 *      openssl pkcs12 -in cert.p12 -nocerts -out pass-key.pem
 * 2. Set Vercel environment variables:
 *    - PASS_CERT: contents of pass-cert.pem (base64 encoded)
 *    - PASS_KEY: contents of pass-key.pem (base64 encoded)
 *    - PASS_KEY_PASSPHRASE: passphrase for the key (if any)
 *    - PASS_TYPE_ID: your pass type identifier (e.g., pass.com.hotbotstudios.vcard)
 *    - TEAM_ID: your Apple Developer Team ID
 * 3. Download Apple's WWDR intermediate certificate:
 *    https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer
 *    Convert: openssl x509 -inform DER -in AppleWWDRCAG4.cer -out wwdr.pem
 *    Set as WWDR_CERT env var (base64 encoded)
 */

// JSZip bundled via node_modules (add to package.json)
let JSZip;
try { JSZip = require('jszip'); } catch(e) { JSZip = null; }

module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const PASS_CERT = process.env.PASS_CERT;
  const PASS_KEY = process.env.PASS_KEY;
  const PASS_KEY_PASSPHRASE = process.env.PASS_KEY_PASSPHRASE || '';
  const WWDR_CERT = process.env.WWDR_CERT;
  const PASS_TYPE_ID = process.env.PASS_TYPE_ID || 'pass.com.hotbotstudios.vcard';
  const TEAM_ID = process.env.TEAM_ID || 'XXXXXXXXXX';

  // If certs not configured, return unsigned pass with setup instructions
  if (!PASS_CERT || !PASS_KEY || !WWDR_CERT) {
    return res.status(503).json({
      error: 'Wallet pass signing not configured',
      setup: 'Set PASS_CERT, PASS_KEY, WWDR_CERT, PASS_TYPE_ID, and TEAM_ID environment variables in Vercel dashboard. See api/wallet.js for instructions.'
    });
  }

  try {
    const cert = Buffer.from(PASS_CERT, 'base64').toString('utf-8');
    const key = Buffer.from(PASS_KEY, 'base64').toString('utf-8');
    const wwdr = Buffer.from(WWDR_CERT, 'base64').toString('utf-8');

    const pass = {
      formatVersion: 1,
      passTypeIdentifier: PASS_TYPE_ID,
      serialNumber: 'HSB-' + Date.now(),
      teamIdentifier: TEAM_ID,
      organizationName: 'HotBot Studios LLP',
      description: 'Harshpreet Singh Bhasin — Digital Business Card',
      foregroundColor: 'rgb(255, 255, 255)',
      backgroundColor: 'rgb(8, 12, 20)',
      labelColor: 'rgb(155, 170, 200)',
      logoText: 'HotBot Studios',
      webServiceURL: 'https://harshpreetbhasin.com',
      authenticationToken: 'vxwxd7J8AlNNFPS8k0a0FfUFtq0ewzFdc',
      barcode: {
        message: 'https://harshpreetbhasin.com',
        format: 'PKBarcodeFormatQR',
        messageEncoding: 'iso-8859-1'
      },
      barcodes: [{
        message: 'https://harshpreetbhasin.com',
        format: 'PKBarcodeFormatQR',
        messageEncoding: 'iso-8859-1'
      }],
      generic: {
        headerFields: [
          { key: 'title', label: 'TITLE', value: 'Managing Partner | CEO' }
        ],
        primaryFields: [
          { key: 'name', label: 'NAME', value: 'Harshpreet Singh Bhasin' }
        ],
        secondaryFields: [
          { key: 'company', label: 'COMPANY', value: 'HotBot Studios LLP' },
          { key: 'phone', label: 'PHONE', value: '+91 97 0000 1534' }
        ],
        auxiliaryFields: [
          { key: 'email', label: 'EMAIL', value: 'Harshpreet@hotbotstudios.com' },
          { key: 'web', label: 'WEBSITE', value: 'hotbotstudios.com' }
        ],
        backFields: [
          { key: 'phone2', label: 'Backup Phone', value: '+91 947 947 0052' },
          { key: 'landline', label: 'Landline', value: '011-4161-0560' },
          { key: 'linkedin', label: 'LinkedIn', value: 'linkedin.com/in/harshpreet-singh-bhasin' },
          { key: 'address', label: 'Office', value: '2nd Floor, M-430 Guruharkishan Nagar, Paschim Vihar, New Delhi 110087, India' },
          { key: 'services', label: 'Services', value: 'AI & Automations, Digital Marketing, Software Development, Web Development, UI/UX Design, SaaS, App Development, Branding' },
          { key: 'website2', label: 'Personal Website', value: 'harshpreetbhasin.com' }
        ]
      }
    };

    const passJson = JSON.stringify(pass);

    // Create icon images (simple branded PNGs)
    const icon = createIconBuffer(29);
    const icon2x = createIconBuffer(58);
    const icon3x = createIconBuffer(87);
    const logo = createIconBuffer(160);
    const logo2x = createIconBuffer(320);

    // Build manifest (SHA1 hash of every file in the pass)
    const files = {
      'pass.json': Buffer.from(passJson),
      'icon.png': icon,
      'icon@2x.png': icon2x,
      'icon@3x.png': icon3x,
      'logo.png': logo,
      'logo@2x.png': logo2x
    };

    const manifest = {};
    for (const [name, data] of Object.entries(files)) {
      manifest[name] = createHash('sha1').update(data).digest('hex');
    }
    const manifestJson = JSON.stringify(manifest);

    // Sign the manifest
    const sign = createSign('SHA256');
    sign.update(manifestJson);
    const signature = sign.sign({
      key: key,
      passphrase: PASS_KEY_PASSPHRASE
    });

    // Build the .pkpass ZIP
    if (!JSZip) {
      return res.status(500).json({ error: 'JSZip not available. Add jszip to package.json.' });
    }

    const zip = new JSZip();
    for (const [name, data] of Object.entries(files)) {
      zip.file(name, data);
    }
    zip.file('manifest.json', manifestJson);
    zip.file('signature', signature);

    const pkpass = await zip.generateAsync({ type: 'nodebuffer', compression: 'DEFLATE' });

    res.setHeader('Content-Type', 'application/vnd.apple.pkpass');
    res.setHeader('Content-Disposition', 'attachment; filename="Harshpreet_Singh_Bhasin.pkpass"');
    res.setHeader('Cache-Control', 'no-cache');
    return res.status(200).send(pkpass);

  } catch (err) {
    console.error('Pass generation error:', err);
    return res.status(500).json({ error: 'Failed to generate pass', details: err.message });
  }
};

// Generate a minimal branded PNG icon buffer
function createIconBuffer(size) {
  // Minimal 1x1 dark PNG as placeholder — replace with actual branded icons
  // In production, store real icon files in the repo and read them
  const { createCanvas } = (() => {
    try { return require('canvas'); } catch(e) { return {}; }
  })();

  if (createCanvas) {
    const canvas = createCanvas(size, size);
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#080c14';
    ctx.fillRect(0, 0, size, size);
    const cx = size / 2, cy = size / 2, r = size * 0.35;
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fillStyle = '#0c1220';
    ctx.fill();
    ctx.strokeStyle = '#1e40af';
    ctx.lineWidth = size * 0.03;
    ctx.stroke();
    ctx.fillStyle = '#e8ecf4';
    ctx.font = `bold ${Math.floor(size * 0.22)}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('HSB', cx, cy);
    return canvas.toBuffer('image/png');
  }

  // Fallback: return the pre-generated icon from the icons directory if available
  try {
    if (size <= 87) return readFileSync(join(__dirname, '..', 'icons', 'icon-192.png'));
    return readFileSync(join(__dirname, '..', 'icons', 'icon-512.png'));
  } catch(e) {
    // Minimal valid 1x1 PNG fallback
    return Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPj/HwADBwIAMCbHYQAAAABJRU5ErkJggg==', 'base64');
  }
}
