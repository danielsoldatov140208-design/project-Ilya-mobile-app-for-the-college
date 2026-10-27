#1
def result_after(score):
    if score >=50:
        return 'Зачет'
    else:
        return 'Незачет'
print(result_after(51))
#2
def print_costs_after(pages):
    if pages >=10:
        return pages * 30 * 0.9
    return pages * 30
print(print_costs_after(10))
#3
def purchase_after(prise, quantity):
    return prise * quantity
print(purchase_after(700, 2))
#4
def fine_before(days):
    if days < 0:
        return "Ошибка"
    elif days <= 3:
        return 0
    else:
        return (days - 3) * 100
print(fine_before(4))
#5
class Student:
    def __init__(self, name, score):
        self.name = name
        self.score = score

    def get_result(self):
        if self.score >= 50:
            return "Зачёт"
        return "Незачёт"


class GrantStudent(Student):
    def get_result(self):
        if self.score >= 70:
            return "Грант сохранён"
        return "Грант не сохранён"

    def get_info(self):
        return f"Студент-грантник: {self.name}, Баллы: {self.score}"



if __name__ == "__main__":
    students = [
        Student("Анна", 49),
        Student("Берик", 50),
        Student("Виктор", 51),
    ]

    grant_students = [
        GrantStudent("Дарья", 69),
        GrantStudent("Елена", 70),
        GrantStudent("Жан", 71),
    ]

    print("--- Проверка Student ---")
    for s in students:
        print(f"{s.name} ({s.score} б.): {s.get_result()}")

    print("\n--- Проверка GrantStudent ---")
    for gs in grant_students:
        print(f"{gs.get_info()} -> Результат: {gs.get_result()}")