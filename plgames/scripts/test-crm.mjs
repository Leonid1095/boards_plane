#!/usr/bin/env node

/**
 * CRM MVP Test Script
 *
 * This script tests the basic CRM functionality by creating sample data
 * and verifying that the models work correctly.
 */

import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';

const prisma = new PrismaClient();

async function testCrmFunctionality() {
  console.log('🚀 Testing PLGames CRM MVP functionality...\n');

  try {
    // Create test workspace (assuming it exists or create mock)
    const workspaceId = 'test-workspace-' + randomUUID();
    const userId = 'test-user-' + randomUUID();

    console.log('📋 Creating test CRM project...');

    // Test project creation
    const project = await prisma.crmProject.create({
      data: {
        id: randomUUID(),
        name: 'Test CRM Project',
        key: 'TEST',
        description: 'A test project for CRM functionality',
        workspaceId: workspaceId,
        leadId: userId,
      },
    });

    console.log('✅ Project created:', project.name, `(${project.key})`);

    console.log('🎯 Creating test issues...');

    // Test issue creation
    const issues = await Promise.all([
      prisma.crmIssue.create({
        data: {
          id: randomUUID(),
          title: 'Setup project infrastructure',
          description: 'Initialize the basic project structure and CI/CD pipeline',
          status: 'DONE',
          priority: 'HIGH',
          type: 'TASK',
          projectId: project.id,
          reporterId: userId,
        },
      }),
      prisma.crmIssue.create({
        data: {
          id: randomUUID(),
          title: 'Implement user authentication',
          description: 'Add login/logout functionality with JWT tokens',
          status: 'IN_PROGRESS',
          priority: 'HIGH',
          type: 'STORY',
          projectId: project.id,
          reporterId: userId,
          assigneeId: userId,
        },
      }),
      prisma.crmIssue.create({
        data: {
          id: randomUUID(),
          title: 'Design database schema',
          description: 'Create the database models and relationships',
          status: 'TODO',
          priority: 'MEDIUM',
          type: 'TASK',
          projectId: project.id,
          reporterId: userId,
        },
      }),
    ]);

    console.log(`✅ Created ${issues.length} test issues`);

    // Test queries
    console.log('🔍 Testing queries...');

    const projectIssues = await prisma.crmIssue.findMany({
      where: { projectId: project.id },
      orderBy: { createdAt: 'desc' },
    });

    console.log(`📊 Found ${projectIssues.length} issues in project`);

    const statusCounts = await prisma.crmIssue.groupBy({
      by: ['status'],
      where: { projectId: project.id },
      _count: { status: true },
    });

    console.log('📈 Issues by status:');
    statusCounts.forEach(count => {
      console.log(`  ${count.status}: ${count._count.status}`);
    });

    // Test comments
    console.log('💬 Testing comments...');

    const comment = await prisma.crmComment.create({
      data: {
        id: randomUUID(),
        content: 'This is a test comment on the authentication task',
        issueId: issues[1].id,
        authorId: userId,
      },
    });

    console.log('✅ Comment created:', comment.content.substring(0, 50) + '...');

    // Test time logging
    console.log('⏱️  Testing time logging...');

    const timeLog = await prisma.crmTimeLog.create({
      data: {
        id: randomUUID(),
        issueId: issues[1].id,
        userId: userId,
        timeSpent: 120, // 2 hours in minutes
        description: 'Working on authentication implementation',
      },
    });

    console.log(`✅ Time logged: ${timeLog.timeSpent} minutes`);

    console.log('\n🎉 All CRM MVP tests passed successfully!');
    console.log('\n📋 Summary:');
    console.log(`   • 1 project created`);
    console.log(`   • ${issues.length} issues created`);
    console.log(`   • 1 comment added`);
    console.log(`   • 1 time log recorded`);

    console.log('\n🧹 Cleaning up test data...');

    // Clean up (optional - comment out if you want to keep test data)
    await prisma.crmTimeLog.deleteMany({ where: { issueId: { in: issues.map(i => i.id) } } });
    await prisma.crmComment.deleteMany({ where: { issueId: { in: issues.map(i => i.id) } } });
    await prisma.crmIssue.deleteMany({ where: { projectId: project.id } });
    await prisma.crmProject.delete({ where: { id: project.id } });

    console.log('✅ Test data cleaned up');

  } catch (error) {
    console.error('❌ CRM test failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Run the test
testCrmFunctionality().catch(console.error);