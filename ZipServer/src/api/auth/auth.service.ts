import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../../db/client';
import { config } from '../../config';
import { createError } from '../../middleware/errorHandler';
import type { AuthTokenPayload, LoginResponse, User } from '../../types';

const SALT_ROUNDS = 12;

export class AuthService {
  // ─── Register ─────────────────────────────────────────────────────────────

  static async register(
    username: string,
    email: string,
    password: string
  ): Promise<LoginResponse> {
    // Check for existing user
    const { data: existing } = await db.client
      .from('users')
      .select('id')
      .or(`email.eq.${email},username.eq.${username}`)
      .maybeSingle();

    if (existing) {
      throw createError('Username or email already in use', 409, 'DUPLICATE_USER');
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const { data: newUser, error } = await db.client
      .from('users')
      .insert({
        id: uuidv4(),
        username,
        email: email.toLowerCase(),
        password_hash: passwordHash,
      })
      .select('id, username, email, avatar_url, country_code, is_admin, created_at')
      .single();

    if (error) throw createError(error.message, 500, 'DB_ERROR');

    return this.buildLoginResponse(newUser);
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  static async login(email: string, password: string): Promise<LoginResponse> {
    const { data: user } = await db.client
      .from('users')
      .select('id, username, email, password_hash, avatar_url, country_code, is_admin, is_banned, created_at')
      .eq('email', email.toLowerCase())
      .maybeSingle();

    if (!user) throw createError('Invalid email or password', 401, 'INVALID_CREDENTIALS');
    if (user.is_banned) throw createError('Account suspended', 403, 'ACCOUNT_BANNED');

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) throw createError('Invalid email or password', 401, 'INVALID_CREDENTIALS');

    // Update last login
    await db.client.from('users').update({ last_login_at: new Date().toISOString() }).eq('id', user.id);

    return this.buildLoginResponse(user);
  }

  // ─── Refresh Token ────────────────────────────────────────────────────────

  static async refreshToken(refreshToken: string): Promise<{ accessToken: string }> {
    const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');

    const { data: stored } = await db.client
      .from('refresh_tokens')
      .select('user_id, expires_at, revoked_at')
      .eq('token_hash', tokenHash)
      .maybeSingle();

    if (!stored || stored.revoked_at || new Date(stored.expires_at) < new Date()) {
      throw createError('Invalid or expired refresh token', 401, 'INVALID_REFRESH_TOKEN');
    }

    const { data: user } = await db.client
      .from('users')
      .select('id, username, email, is_admin')
      .eq('id', stored.user_id)
      .single();

    if (!user) throw createError('User not found', 404, 'USER_NOT_FOUND');

    const payload: AuthTokenPayload = {
      userId: user.id,
      email: user.email,
      username: user.username,
      isAdmin: user.is_admin,
    };

    const accessToken = jwt.sign(payload, config.jwt.secret, { expiresIn: config.jwt.expiresIn });
    return { accessToken };
  }

  // ─── Logout ──────────────────────────────────────────────────────────────

  static async logout(userId: string): Promise<void> {
    await db.client
      .from('refresh_tokens')
      .update({ revoked_at: new Date().toISOString() })
      .eq('user_id', userId)
      .is('revoked_at', null);
  }

  // ─── Get User By ID ──────────────────────────────────────────────────────

  static async getUserById(userId: string): Promise<{ data: User | null; error: unknown }> {
    try {
      const { data: user, error } = await db.client
        .from('users')
        .select('id, username, email, avatar_url, country_code, is_admin, created_at')
        .eq('id', userId)
        .maybeSingle();

      if (error) return { data: null, error };
      if (!user) return { data: null, error: null };

      const userObj: User = {
        id: user.id,
        username: user.username,
        email: user.email,
        avatarUrl: user.avatar_url,
        countryCode: user.country_code,
        isAdmin: user.is_admin,
        createdAt: user.created_at,
      };

      return { data: userObj, error: null };
    } catch (error) {
      return { data: null, error };
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  private static async buildLoginResponse(user: Record<string, unknown>): Promise<LoginResponse> {
    const payload: AuthTokenPayload = {
      userId: user.id as string,
      email: user.email as string,
      username: user.username as string,
      isAdmin: user.is_admin as boolean,
    };

    const accessToken = jwt.sign(payload, config.jwt.secret, {
      expiresIn: config.jwt.expiresIn,
    });

    const refreshToken = uuidv4();
    const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');

    try {
      await db.client.from('refresh_tokens').insert({
        user_id: user.id,
        token_hash: tokenHash,
        expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      });
    } catch (err) {
      throw createError('Failed to store refresh token', 500, 'DB_ERROR');
    }

    const userObj: User = {
      id: user.id as string,
      username: user.username as string,
      email: user.email as string,
      avatarUrl: user.avatar_url as string | undefined,
      countryCode: user.country_code as string | undefined,
      isAdmin: user.is_admin as boolean,
      createdAt: user.created_at as string,
    };

    return { accessToken, refreshToken, user: userObj };
  }
}
