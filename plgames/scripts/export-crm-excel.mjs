#!/usr/bin/env node

/**
 * CRM Data Export Script
 * Exports CRM projects and issues to Excel format
 */

import { createRequire } from 'module';
import { writeFileSync } from 'fs';
import { join } from 'path';

const require = createRequire(import.meta.url);

// Simple CSV export (can be enhanced with proper Excel library later)
function exportToCSV(data, filename) {
  if (!data || data.length === 0) {
    console.log(`No data to export for ${filename}`);
    return;
  }

  const headers = Object.keys(data[0]);
  const csvContent = [
    headers.join(','),
    ...data.map(row =>
      headers.map(header => {
        const value = row[header];
        // Escape commas and quotes in CSV
        if (typeof value === 'string' && (value.includes(',') || value.includes('"'))) {
          return `"${value.replace(/"/g, '""')}"`;
        }
        return value || '';
      }).join(',')
    )
  ].join('\n');

  const outputPath = join(process.cwd(), `${filename}.csv`);
  writeFileSync(outputPath, csvContent, 'utf8');
  console.log(`✅ Exported ${data.length} records to ${outputPath}`);
}

// Mock data for demonstration (replace with actual database queries)
function generateMockCRMData() {
  const projects = [
    {
      id: '1',
      name: 'Website Redesign',
      key: 'WEBSITE',
      description: 'Complete redesign of company website',
      createdAt: '2024-01-15',
      issueCount: 12
    },
    {
      id: '2',
      name: 'Mobile App Development',
      key: 'MOBILE',
      description: 'Native mobile app for iOS and Android',
      createdAt: '2024-02-01',
      issueCount: 8
    }
  ];

  const issues = [
    {
      id: '1',
      title: 'Design homepage mockups',
      status: 'DONE',
      priority: 'HIGH',
      type: 'TASK',
      projectKey: 'WEBSITE',
      assignee: 'john.doe@example.com',
      reporter: 'jane.smith@example.com',
      createdAt: '2024-01-16',
      updatedAt: '2024-01-20'
    },
    {
      id: '2',
      title: 'Implement user authentication',
      status: 'IN_PROGRESS',
      priority: 'HIGH',
      type: 'TASK',
      projectKey: 'MOBILE',
      assignee: 'bob.wilson@example.com',
      reporter: 'alice.johnson@example.com',
      createdAt: '2024-02-02',
      updatedAt: '2024-02-10'
    },
    {
      id: '3',
      title: 'Fix login button styling',
      status: 'TODO',
      priority: 'MEDIUM',
      type: 'BUG',
      projectKey: 'WEBSITE',
      assignee: null,
      reporter: 'john.doe@example.com',
      createdAt: '2024-01-18',
      updatedAt: '2024-01-18'
    }
  ];

  return { projects, issues };
}

async function main() {
  console.log('🚀 Starting CRM data export...');

  try {
    // Generate mock data (replace with actual database queries)
    const { projects, issues } = generateMockCRMData();

    // Export projects
    exportToCSV(projects, 'crm-projects');

    // Export issues
    exportToCSV(issues, 'crm-issues');

    console.log('✅ CRM export completed successfully!');
    console.log('\n📊 Summary:');
    console.log(`   Projects: ${projects.length}`);
    console.log(`   Issues: ${issues.length}`);

  } catch (error) {
    console.error('❌ Export failed:', error.message);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { exportToCSV, generateMockCRMData };