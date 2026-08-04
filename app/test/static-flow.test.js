// Copyright IBM Corp. All Rights Reserved.
// #
// SPDX-License-Identifier: Apache-2.0

'use strict';
const assert = require('assert');
const { listCourses, findCourse } = require('../src/services/catalog');
const { buildVaultAuthorizationDetails } = require('../src/services/verify');

process.env.VAULT_SECRET_API_PATH = 'course-tools/data/premium-enrollment';
const courses = listCourses();
assert(courses.some(c => c.premium), 'At least one premium course is required');
assert(courses.some(c => !c.premium), 'At least one standard course is required');
assert.strictEqual(findCourse('PREM-801').premium, true);
const details = buildVaultAuthorizationDetails();
assert.deepStrictEqual(details, [{
  type: 'vault:path_access',
  path: 'course-tools/data/premium-enrollment',
  capabilities: ['read']
}]);
console.log('Static flow tests passed.');
