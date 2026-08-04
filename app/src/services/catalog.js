// Copyright IBM Corp. All Rights Reserved.
// #
// SPDX-License-Identifier: Apache-2.0

'use strict';
const path = require('path');
const fs = require('fs');
const catalogPath = path.resolve(__dirname, '../../../config/courses.json');
const courses = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));

function listCourses() {
  return courses.map(course => ({ ...course }));
}

function findCourse(courseId) {
  return courses.find(course => course.id === courseId) || null;
}

module.exports = { listCourses, findCourse };
