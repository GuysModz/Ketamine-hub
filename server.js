const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "ketamine123";

const DB_PATH = path.join(__dirname, 'database', 'database.json');

// Ensure database directory and file exist
function initDb() {
    const dir = path.dirname(DB_PATH);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    if (!fs.existsSync(DB_PATH)) {
        const initialData = {
            keys: [
                {
                    key: "KETAMINE-TEST-KEY",
                    createdAt: new Date().toISOString(),
                    expiresAt: null,
                    usedBy: null,
                    hwid: null,
                    maxUses: 1,
                    uses: 0,
                    active: true,
                    note: "Default test key"
                }
            ],
            settings: {
                hubName: "Ketamine Hub",
                version: "1.0",
                scriptUrl: "http://localhost:3000/payload.lua"
            },
            stats: {
                totalKeysGenerated: 1,
                totalValidations: 0,
                lastValidation: null
            }
        };
        fs.writeFileSync(DB_PATH, JSON.stringify(initialData, null, 2), 'utf8');
    }
}

// Helper to read DB
function readDb() {
    initDb();
    try {
        const data = fs.readFileSync(DB_PATH, 'utf8');
        return JSON.parse(data);
    } catch (e) {
        console.error("Error reading database:", e);
        return { keys: [], settings: {}, stats: {} };
    }
}

// Helper to write DB
function writeDb(data) {
    initDb();
    try {
        fs.writeFileSync(DB_PATH, JSON.stringify(data, null, 2), 'utf8');
        return true;
    } catch (e) {
        console.error("Error writing database:", e);
        return false;
    }
}

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use('/docs', express.static(path.join(__dirname, 'website docs')));

// Route to serve the local payload file dynamically
app.get('/payload.lua', (req, res) => {
    const payloadPath = path.join(__dirname, 'sell_lemons_payload.lua');
    if (fs.existsSync(payloadPath)) {
        res.setHeader('Content-Type', 'text/plain');
        res.sendFile(payloadPath);
    } else {
        res.status(404).send('-- Payload file not found on server');
    }
});

// Route to serve the UI Library
app.get('/ketamineUI.lua', (req, res) => {
    const libPath = path.join(__dirname, 'public', 'src', 'ketamineUI.lua');
    if (fs.existsSync(libPath)) {
        res.setHeader('Content-Type', 'text/plain');
        res.sendFile(libPath);
    } else {
        res.status(404).send('-- UI Library not found');
    }
});

// Admin Password Middleware
function requireAdmin(req, res, next) {
    const pwd = req.headers['x-admin-password'];
    if (pwd === ADMIN_PASSWORD) {
        next();
    } else {
        res.status(401).json({ error: "Unauthorized: Invalid Admin Password" });
    }
}

// API: Get all keys and database details
app.get('/api/data', requireAdmin, (req, res) => {
    const db = readDb();
    res.json(db);
});

// API: Add a key
app.post('/api/keys', requireAdmin, (req, res) => {
    const { key, expiresAt, maxUses, note, hwidLocked } = req.body;
    if (!key) {
        return res.status(400).json({ error: "Key is required" });
    }

    const db = readDb();
    if (db.keys.some(k => k.key === key)) {
        return res.status(400).json({ error: "Key already exists" });
    }

    const newKey = {
        key: key,
        createdAt: new Date().toISOString(),
        expiresAt: expiresAt || null,
        usedBy: null,
        hwid: null,
        maxUses: maxUses ? parseInt(maxUses) : 1,
        uses: 0,
        active: true,
        note: note || "",
        hwidLocked: hwidLocked !== false
    };

    db.keys.push(newKey);
    db.stats.totalKeysGenerated = (db.stats.totalKeysGenerated || 0) + 1;
    
    if (writeDb(db)) {
        res.status(201).json(newKey);
    } else {
        res.status(500).json({ error: "Failed to write database" });
    }
});

// API: Delete a key
app.delete('/api/keys/:key', requireAdmin, (req, res) => {
    const keyToDelete = req.params.key;
    const db = readDb();
    const index = db.keys.findIndex(k => k.key === keyToDelete);
    
    if (index === -1) {
        return res.status(404).json({ error: "Key not found" });
    }

    db.keys.splice(index, 1);
    if (writeDb(db)) {
        res.json({ success: true });
    } else {
        res.status(500).json({ error: "Failed to write database" });
    }
});

// API: Toggle key status
app.patch('/api/keys/:key/toggle', requireAdmin, (req, res) => {
    const targetKey = req.params.key;
    const db = readDb();
    const keyData = db.keys.find(k => k.key === targetKey);

    if (!keyData) {
        return res.status(404).json({ error: "Key not found" });
    }

    keyData.active = !keyData.active;
    if (writeDb(db)) {
        res.json(keyData);
    } else {
        res.status(500).json({ error: "Failed to write database" });
    }
});

// API: Update settings
app.post('/api/settings', requireAdmin, (req, res) => {
    const { hubName, version, scriptUrl } = req.body;
    const db = readDb();

    if (hubName) db.settings.hubName = hubName;
    if (version) db.settings.version = version;
    if (scriptUrl) db.settings.scriptUrl = scriptUrl;

    if (writeDb(db)) {
        res.json(db.settings);
    } else {
        res.status(500).json({ error: "Failed to write database" });
    }
});

// API: Reset HWID for a key
app.post('/api/keys/:key/reset-hwid', requireAdmin, (req, res) => {
    const targetKey = req.params.key;
    const db = readDb();
    const keyData = db.keys.find(k => k.key === targetKey);

    if (!keyData) {
        return res.status(404).json({ error: "Key not found" });
    }

    keyData.hwid = null;
    keyData.usedBy = null;
    keyData.uses = 0;

    if (writeDb(db)) {
        res.json(keyData);
    } else {
        res.status(500).json({ error: "Failed to write database" });
    }
});

// API: Validate Key (Used by the Roblox Client)
app.get('/api/validate', (req, res) => {
    const { key, hwid, user, placeId } = req.query;
    if (!key) {
        return res.status(400).json({ status: "error", message: "Missing key parameter" });
    }

    const db = readDb();
    const keyData = db.keys.find(k => k.key === key);

    if (!keyData) {
        return res.json({ status: "invalid", message: "Key does not exist" });
    }

    if (!keyData.active) {
        return res.json({ status: "inactive", message: "Key is disabled" });
    }

    // Check expiration
    if (keyData.expiresAt && new Date(keyData.expiresAt) < new Date()) {
        keyData.active = false;
        writeDb(db);
        return res.json({ status: "expired", message: "Key has expired" });
    }

    // Check HWID lock
    if (keyData.hwidLocked !== false) {
        if (keyData.hwid && keyData.hwid !== hwid) {
            return res.json({ status: "hwid_mismatch", message: "HWID does not match key owner" });
        }
        
        // Lock HWID on first validate if not locked yet
        if (!keyData.hwid && hwid) {
            keyData.hwid = hwid;
            keyData.usedBy = user || "Unknown";
        }
    } else {
        keyData.usedBy = user || "Shared Client";
    }

    // Check usage limits
    if (keyData.hwidLocked !== false) {
        if (keyData.uses >= keyData.maxUses && keyData.maxUses > 0 && !keyData.hwid) {
            return res.json({ status: "exhausted", message: "Key usage limit reached" });
        }
    } else {
        if (keyData.uses >= keyData.maxUses && keyData.maxUses > 0) {
            return res.json({ status: "exhausted", message: "Key usage limit reached" });
        }
    }

    // Game hub detection & validation
    let targetScriptUrl = db.settings.scriptUrl || "";

    keyData.uses = (keyData.uses || 0) + 1;
    
    // Update global stats
    db.stats.totalValidations = (db.stats.totalValidations || 0) + 1;
    db.stats.lastValidation = new Date().toISOString();

    writeDb(db);

    res.json({
        status: "success",
        message: "Authentication successful",
        scriptUrl: targetScriptUrl
    });
});

// Serve frontend
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

initDb();

app.listen(PORT, () => {
    console.log(`Ketamine Hub Dashboard Server running at http://localhost:${PORT}`);
});
