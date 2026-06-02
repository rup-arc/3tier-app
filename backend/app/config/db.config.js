const sslEnabled = process.env.DB_SSL === "true";
const port = process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432;

module.exports = {
  HOST: process.env.DB_HOST,
  USER: process.env.DB_USER,
  PASSWORD: process.env.DB_PASSWORD,
  DB: process.env.DB_NAME,
  PORT: port,
  dialect: "postgres",
  dialectOptions: sslEnabled
    ? {
        ssl: {
          require: true,
          rejectUnauthorized: false
        }
      }
    : {},

  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
};
