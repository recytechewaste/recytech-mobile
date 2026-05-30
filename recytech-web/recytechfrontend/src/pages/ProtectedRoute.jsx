import { Navigate } from 'react-router-dom';

const ProtectedRoute = ({ children, allowedRoles }) => {
    // Retrieve user info from localStorage
    const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}');

    // 1. Check if user is logged in
    if (!userInfo || !userInfo.token) {
        return <Navigate to="/login" replace />;
    }

    // 2. Check if the user's role is permitted to see this page
    // If allowedRoles is provided and user's role is not in the list, redirect to unauthorized
    if (allowedRoles && !allowedRoles.includes(userInfo.role)) {
        return <Navigate to="/unauthorized" replace />;
    }

    return children;
};

export default ProtectedRoute;