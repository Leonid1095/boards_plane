import type { OnModuleDestroy } from '@nestjs/common';
import { Injectable } from '@nestjs/common';
import type { PrismaClient as PrismaClientType } from '@prisma/client';
import pkg from '@prisma/client';
const { PrismaClient } = pkg;

import { Config } from '../config';

@Injectable()
export class PrismaFactory implements OnModuleDestroy {
  static INSTANCE: PrismaClientType | null = null;
  readonly #instance: PrismaClientType;

  constructor(config: Config) {
    this.#instance = new PrismaClient(config.db.prisma);
    PrismaFactory.INSTANCE = this.#instance;
  }

  get() {
    return this.#instance;
  }

  async onModuleDestroy() {
    await PrismaFactory.INSTANCE?.$disconnect();
    PrismaFactory.INSTANCE = null;
  }
}
