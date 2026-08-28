const roleGuard = (...roles) => {
    return (req, res, next) => {
        // Admins can bypass any role check
        if (!req.user || (!roles.includes(req.user.role) && req.user.role !== 'admin')) {
            return res.status(403).json({
                message: `Role (${req.user ? req.user.role : 'none'}) is not allowed to access this resource`
            });
        }
        next();
    };
};

module.exports = roleGuard;
