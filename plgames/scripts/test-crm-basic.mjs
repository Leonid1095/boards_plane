#!/usr/bin/env node

/**
 * Basic CRM sanity check for PLGames.
 * Verifies that CRM files exist, schema models are present,
 * branding points at PLGames (no hard-coded domains),
 * and paywall stays disabled.
 */

import fs from 'fs';
import path from 'path';

const log = (label) => console.log(`\n== ${label}`);

log('Checking CRM files');
const crmFiles = [
  'blocksuite/affine/blocks/crm/package.json',
  'blocksuite/affine/blocks/crm/src/crm-block.ts',
  'blocksuite/affine/blocks/crm/src/config.ts',
  'packages/backend/server/src/models/crm-project.ts',
  'packages/backend/server/src/models/crm-issue.ts',
  'packages/backend/server/src/models/crm-sprint.ts',
  'docs/CRM.md',
];

let ok = true;
for (const file of crmFiles) {
  const filePath = path.join(process.cwd(), file);
  if (fs.existsSync(filePath)) {
    console.log(`  ✅ ${file}`);
  } else {
    console.log(`  ❌ ${file} missing`);
    ok = false;
  }
}

log('Checking CRM schema');
const schemaPath = path.join(process.cwd(), 'packages/backend/server/schema.prisma');
if (fs.existsSync(schemaPath)) {
  const schema = fs.readFileSync(schemaPath, 'utf8');
  const hasCrmModels =
    schema.includes('model CrmProject') &&
    schema.includes('model CrmIssue') &&
    schema.includes('model CrmSprint');
  console.log(hasCrmModels ? '  ✅ CRM models present' : '  ❌ CRM models missing');
  ok &&= hasCrmModels;
} else {
  console.log('  ❌ schema.prisma missing');
  ok = false;
}

log('Checking branding');
const brandPath = path.join(process.cwd(), 'packages/common/env/src/brand.ts');
if (fs.existsSync(brandPath)) {
  const brand = fs.readFileSync(brandPath, 'utf8');
  const hasName = brand.includes('PLGames');
  const hasOldDomain = brand.match(/affine\.pro/i);
  console.log(hasName ? '  ✅ PLGames brand found' : '  ❌ PLGames brand missing');
  console.log(!hasOldDomain ? '  ✅ No hard-coded legacy domain' : '  ❌ Legacy domain found');
  ok &&= hasName && !hasOldDomain;
} else {
  console.log('  ❌ brand.ts missing');
  ok = false;
}

log('Checking paywall toggle');
const modulesPath = path.join(process.cwd(), 'packages/frontend/core/src/modules/index.ts');
if (fs.existsSync(modulesPath)) {
  const modules = fs.readFileSync(modulesPath, 'utf8');
  const paywallDisabled = modules.includes('// configurePaywallModule(framework);');
  console.log(paywallDisabled ? '  ✅ Paywall disabled' : '  ❌ Paywall enabled');
  ok &&= paywallDisabled;
} else {
  console.log('  ❌ modules index missing');
  ok = false;
}

log('Result');
if (ok) {
  console.log('  ✅ CRM sanity check passed');
  process.exit(0);
} else {
  console.log('  ❌ CRM sanity check failed');
  process.exit(1);
}
