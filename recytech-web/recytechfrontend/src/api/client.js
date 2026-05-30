import axios from 'axios';

const api = axios.create({
    baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000/api',
});

api.interceptors.request.use((config) => {
    const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}');

    if (userInfo.token) {
        config.headers.Authorization = `Bearer ${userInfo.token}`;
    }

    return config;
});

export default api;
