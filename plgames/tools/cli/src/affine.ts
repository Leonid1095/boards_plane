import { Workspace } from '@affine-tools/utils/workspace';
import { BRAND } from '@affine/env/brand';
import { Cli } from 'clipanion';

import { BuildCommand } from './build';
import { BundleCommand } from './bundle';
import { CertCommand } from './cert';
import { CleanCommand } from './clean';
import type { CliContext } from './context';
import { DevCommand } from './dev';
import { InitCommand } from './init';
import { RunCommand } from './run';

const cli = new Cli<CliContext>({
  binaryName: 'plgames',
  binaryVersion: '0.0.0',
  binaryLabel: `${BRAND.productName} Monorepo Tools`,
  enableColors: true,
  enableCapture: true,
});

cli.register(RunCommand);
cli.register(InitCommand);
cli.register(CleanCommand);
cli.register(BuildCommand);
cli.register(DevCommand);
cli.register(BundleCommand);
cli.register(CertCommand);

await cli.runExit(process.argv.slice(2), {
  workspace: new Workspace(),
  stdin: process.stdin,
  stdout: process.stdout,
  stderr: process.stderr,
});
