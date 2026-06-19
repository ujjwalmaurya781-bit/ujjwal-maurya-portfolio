const fs = require('fs');
const path = require('path');

module.exports = (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
        res.status(200).end();
        return;
    }
    
    const { folder } = req.query;
    if (!folder) {
        return res.status(400).send('Missing folder parameter');
    }
    
    // Security clean
    let cleanFolder = folder.replace(/\.\./g, '').trim();
    
    let searchDir = path.join(process.cwd(), cleanFolder);
    if (!fs.existsSync(searchDir)) {
        if (!cleanFolder.startsWith('public/')) {
            searchDir = path.join(process.cwd(), 'public', cleanFolder);
        }
    }
    
    if (!fs.existsSync(searchDir)) {
        return res.status(404).send('Folder not found: ' + cleanFolder);
    }
    
    try {
        const stats = fs.statSync(searchDir);
        if (!stats.isDirectory()) {
            return res.status(400).send('Path is not a directory');
        }
        
        const items = fs.readdirSync(searchDir);
        const subdirs = items.filter(item => {
            const fullItemPath = path.join(searchDir, item);
            return fs.statSync(fullItemPath).isDirectory();
        });
        
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.status(200).json(subdirs);
    } catch (error) {
        console.error(error);
        res.status(500).send('Server error: ' + error.message);
    }
};
