const fs = require('fs');
const path = require('path');

module.exports = (req, res) => {
    // Enable CORS
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
    
    // Try to locate folder relative to workspace root
    // Vercel serverless functions include the repository files, but public folder files
    // might be bundled inside public/ or at the root. We check both paths.
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
        
        const files = fs.readdirSync(searchDir);
        const imageFiles = files.filter(file => {
            const ext = path.extname(file).toLowerCase();
            return ['.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp'].includes(ext);
        }).map(file => {
            // Return public-facing relative URL path (starts with assets/...)
            const folderPart = cleanFolder.replace(/^public\//, '').replace(/\/$/, '');
            return `${folderPart}/${file}`;
        });
        
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.status(200).json(imageFiles);
    } catch (error) {
        console.error(error);
        res.status(500).send('Server error: ' + error.message);
    }
};
