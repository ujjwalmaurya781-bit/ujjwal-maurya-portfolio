module.exports = (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
        res.status(200).end();
        return;
    }
    
    // Serverless functions on Vercel are read-only and ephemeral.
    // Return a clean forbidden message for client interface.
    res.status(403).send('Asset uploads are disabled in the live production portfolio demo.');
};
