import unittest
from ekeb_service import print_cost, exam_result, Student, GrantStudent, ExcellentStudent


class TestPrintCost(unittest.TestCase):
    def test_pages_negative(self):
        with self.assertRaises(ValueError):
            print_cost(-1)

    def test_pages_zero(self):
        self.assertEqual(print_cost(0), 0)

    def test_pages_one(self):
        self.assertEqual(print_cost(1), 30)

    def test_pages_nine(self):
        self.assertEqual(print_cost(9), 270)

    def test_pages_ten_boundary(self):
        # 10 страниц * 30 тенге * 0.9 (10% скидка) = 270
        self.assertEqual(print_cost(10), 270)

    def test_pages_eleven(self):
        # 11 страниц * 30 тенге * 0.9 = 297
        self.assertEqual(print_cost(11), 297)


class TestExamResult(unittest.TestCase):
    def test_score_minus_one(self):
        with self.assertRaises(ValueError):
            exam_result(-1)

    def test_score_zero(self):
        self.assertEqual(exam_result(0), "Незачёт")

    def test_score_forty_nine(self):
        self.assertEqual(exam_result(49), "Незачёт")

    def test_score_fifty_boundary(self):
        self.assertEqual(exam_result(50), "Зачёт")

    def test_score_fifty_one(self):
        self.assertEqual(exam_result(51), "Зачёт")

    def test_score_one_hundred(self):
        self.assertEqual(exam_result(100), "Зачёт")

    def test_score_one_hundred_one(self):
        with self.assertRaises(ValueError):
            exam_result(101)


class TestStudent(unittest.TestCase):
    def setUp(self):
        self.student = Student("Алия", 50)

    def test_initial_attributes(self):
        self.assertEqual(self.student.name, "Алия")
        self.assertEqual(self.student.score, 50)

    def test_has_passed_boundary(self):
        self.assertTrue(self.student.has_passed())

    def test_add_ten_points(self):
        self.student.add_points(10)
        self.assertEqual(self.student.score, 60)

    def test_max_score_cap(self):
        self.student.add_points(60)  # 50 + 60 = 110 -> должно ограниченно быть 100
        self.assertEqual(self.student.score, 100)

    def test_add_negative_points(self):
        with self.assertRaises(ValueError):
            self.student.add_points(-10)


class TestGrantStudent(unittest.TestCase):
    def test_is_instance_of_student(self):
        grant_student = GrantStudent("Берик", 70)
        self.assertIsInstance(grant_student, Student)

    def test_grant_status_boundaries(self):
        gs69 = GrantStudent("Гульназ", 69)
        gs70 = GrantStudent("Данияр", 70)
        gs71 = GrantStudent("Еркебулан", 71)

        self.assertEqual(gs69.grant_status(), "Грант не сохранён")
        self.assertEqual(gs70.grant_status(), "Грант сохранён")
        self.assertEqual(gs71.grant_status(), "Грант сохранён")

    def test_inherited_add_points_and_grant_status(self):
        gs = GrantStudent("Аружан", 65)
        self.assertEqual(gs.grant_status(), "Грант не сохранён")

        gs.add_points(10)  # 65 + 10 = 75
        self.assertEqual(gs.score, 75)
        self.assertEqual(gs.grant_status(), "Грант сохранён")


class TestExcellentStudent(unittest.TestCase):
    def test_scholarship_levels(self):
        es74 = ExcellentStudent("Мирас", 74)
        es75 = ExcellentStudent("Дина", 75)
        es89 = ExcellentStudent("Темирлан", 89)
        es90 = ExcellentStudent("Зарина", 90)
        es100 = ExcellentStudent("Асхат", 100)

        self.assertEqual(es74.scholarship(), 0)
        self.assertEqual(es75.scholarship(), 15000)
        self.assertEqual(es89.scholarship(), 15000)
        self.assertEqual(es90.scholarship(), 30000)
        self.assertEqual(es100.scholarship(), 30000)


if __name__ == "__main__":
    unittest.main()