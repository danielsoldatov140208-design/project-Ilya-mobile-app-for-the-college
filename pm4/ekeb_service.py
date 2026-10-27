
def print_cost(pages):
    if pages < 0:
        raise ValueError("Количество страниц не может быть отрицательным")
    total = pages * 30
    if pages >= 10:
        total = total * 0.9
    return total

def exam_result(score):
    if score < 0 or score > 100:
        raise ValueError("Недопустимый балл")
    if score >= 50:
        return "Зачёт"
    return "Незачёт"

class Student:
    def __init__(self, name, score):
        self.name = name
        self.score = score

    def has_passed(self):
        return self.score >= 50

    def add_points(self, points):
        if points < 0:
            raise ValueError("Количество добавляемых баллов не может быть отрицательным")
        self.score = min(100, self.score + points)
        return self.score

class GrantStudent(Student):
    def grant_status(self):
        if self.score >= 70:
            return "Грант сохранён"
        return "Грант не сохранён"

class ExcellentStudent(Student):
    def scholarship(self):
        if 90 <= self.score <= 100:
            return 30000
        elif 75 <= self.score <= 89:
            return 15000
        return 0