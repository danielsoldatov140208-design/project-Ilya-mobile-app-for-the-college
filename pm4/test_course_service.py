import unittest
from course_service import Course, IntensiveCourse


class TestCourse(unittest.TestCase):
    def test_course_creation_valid(self):
        course = Course("Python TDD", 15)
        self.assertEqual(course.name, "Python TDD")
        self.assertEqual(course.capacity, 15)

    def test_initial_enrolled_is_zero(self):
        course = Course("Python TDD", 10)
        self.assertEqual(course.enrolled, 0)

    def test_course_empty_name_raises_value_error(self):
        with self.assertRaises(ValueError):
            Course("", 10)
        with self.assertRaises(ValueError):
            Course("   ", 10)

    def test_course_invalid_capacity_raises_value_error(self):
        with self.assertRaises(ValueError):
            Course("Python TDD", 0)
        with self.assertRaises(ValueError):
            Course("Python TDD", -5)

    def test_available_places_initial(self):
        course = Course("Python TDD", 10)
        self.assertEqual(course.available_places(), 10)

    def test_enroll_single_student(self):
        course = Course("Python TDD", 5)
        remaining = course.enroll()
        self.assertEqual(course.enrolled, 1)
        self.assertEqual(remaining, 4)

    def test_enroll_multiple_students(self):
        course = Course("Python TDD", 5)
        course.enroll()
        remaining = course.enroll()
        self.assertEqual(course.enrolled, 2)
        self.assertEqual(remaining, 3)

    def test_enroll_last_place(self):
        course = Course("Python TDD", 2)
        course.enroll()
        remaining = course.enroll()
        self.assertEqual(course.enrolled, 2)
        self.assertEqual(remaining, 0)

    def test_enroll_over_capacity_raises_error(self):
        course = Course("Python TDD", 1)
        course.enroll()
        with self.assertRaises(ValueError):
            course.enroll()

    def test_cancel_enrollment_after_one_enroll(self):
        course = Course("Python TDD", 5)
        course.enroll()
        remaining = course.cancel_enrollment()
        self.assertEqual(course.enrolled, 0)
        self.assertEqual(remaining, 5)

    def test_cancel_enrollment_when_zero_raises_error(self):
        course = Course("Python TDD", 5)
        with self.assertRaises(ValueError):
            course.cancel_enrollment()

    def test_cancel_enrollment_restores_available_place(self):
        course = Course("Python TDD", 1)
        course.enroll()
        self.assertTrue(course.is_full)
        course.cancel_enrollment()
        self.assertFalse(course.is_full)
        self.assertEqual(course.available_places(), 1)

    def test_is_full_property(self):
        course = Course("Python TDD", 2)
        self.assertFalse(course.is_full)
        course.enroll()
        self.assertFalse(course.is_full)
        course.enroll()
        self.assertTrue(course.is_full)


class TestIntensiveCourse(unittest.TestCase):
    def test_is_instance_of_course(self):
        ic = IntensiveCourse("Fast Python", 10, 8)
        self.assertIsInstance(ic, Course)

    def test_workload_level_boundaries(self):
        ic6 = IntensiveCourse("Course 6h", 10, 6)
        ic10 = IntensiveCourse("Course 10h", 10, 10)
        ic11 = IntensiveCourse("Course 11h", 10, 11)
        ic20 = IntensiveCourse("Course 20h", 10, 20)

        self.assertEqual(ic6.workload_level(), "средняя")
        self.assertEqual(ic10.workload_level(), "средняя")
        self.assertEqual(ic11.workload_level(), "высокая")
        self.assertEqual(ic20.workload_level(), "высокая")

    def test_invalid_hours_raises_value_error(self):
        with self.assertRaises(ValueError):
            IntensiveCourse("Course 5h", 10, 5)
        with self.assertRaises(ValueError):
            IntensiveCourse("Course 21h", 10, 21)

    def test_inherited_methods(self):
        ic = IntensiveCourse("Fast Python", 2, 12)
        self.assertEqual(ic.available_places(), 2)
        ic.enroll()
        self.assertEqual(ic.available_places(), 1)
        self.assertFalse(ic.is_full)
        ic.enroll()
        self.assertTrue(ic.is_full)


if __name__ == "__main__":
    unittest.main()