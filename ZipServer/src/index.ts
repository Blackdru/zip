import 'dotenv/config';
import app from './app';
import { config } from './config';
import { logger } from './utils/logger';
import { startAllCronJobs } from './cron/scheduler';

const server = app.listen(config.port, () => {
  logger.info(`🚀 ZIP Server running on port ${config.port} [${config.env}]`);
  logger.info(`   Health: http://localhost:${config.port}/health`);
  logger.info(`   API:    http://localhost:${config.port}/api/v1`);
});

// Start scheduled jobs in production / development (not in test)
if (config.env !== 'test') {
  startAllCronJobs();
}

// Graceful shutdown
const shutdown = (signal: string) => {
  logger.info(`Received ${signal}. Graceful shutdown...`);
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled Rejection:', reason);
});

process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

export default server;
