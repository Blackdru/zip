import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import type { AuthTokenPayload } from '../types';

// Extend Express Request to carry authenticated user
declare global {
  namespace Express {
    interface Request {
      user?: AuthTokenPayload;
    }
  }
}

export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ success: false, error: 'Missing or invalid authorization header' });
    return;
  }

  const token = authHeader.slice(7);
  try {
    const payload = jwt.verify(token, config.jwt.secret);

    if (
      typeof payload === 'object' &&
      payload !== null &&
      typeof (payload as Record<string, unknown>).userId === 'string' &&
      typeof (payload as Record<string, unknown>).username === 'string'
    ) {
      req.user = payload as AuthTokenPayload;
      next();
    } else {
      res.status(401).json({ success: false, error: 'Invalid token payload' });
    }
  } catch {
    res.status(401).json({ success: false, error: 'Invalid or expired token' });
  }
}

export function adminMiddleware(req: Request, res: Response, next: NextFunction): void {
  if (!req.user?.isAdmin) {
    res.status(403).json({ success: false, error: 'Admin access required' });
    return;
  }
  next();
}
