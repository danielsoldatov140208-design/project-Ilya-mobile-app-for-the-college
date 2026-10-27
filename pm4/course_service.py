class Course:
    def __init__(self, name: str, capacity: int):
        if not isinstance(name, str) or not name.strip():
            raise ValueError("Название курса не может быть пустым")
        if not isinstance(capacity, int) or capacity <= 0:
            raise ValueError("Количество мест должно быть положительным целым числом")

        self.name = name.strip()
        self.capacity = capacity
        self.enrolled = 0
        self.waitlist = 0

    def available_places(self) -> int:
        return self.capacity - self.enrolled

    def enroll(self, add_to_waitlist: bool = False) -> int:
        if self.is_full:
            if add_to_waitlist:
                self.waitlist += 1
                return 0
            raise ValueError("Нет свободных мест на курс")

        self.enrolled += 1
        return self.available_places()

    def cancel_enrollment(self) -> int:
        if self.enrolled == 0:
            raise ValueError("Нет зарегистрированных студентов для отмены")

        if self.waitlist > 0:
            self.waitlist -= 1
        else:
            self.enrolled -= 1

        return self.available_places()

    @property
    def is_full(self) -> bool:
        return self.enrolled >= self.capacity


class IntensiveCourse(Course):
    def __init__(self, name: str, capacity: int, hours_per_week: int):
        super().__init__(name, capacity)
        if not isinstance(hours_per_week, int) or not (6 <= hours_per_week <= 20):
            raise ValueError("Нагрузка должна быть от 6 до 20 часов в неделю")
        self.hours_per_week = hours_per_week

    def workload_level(self) -> str:
        if 6 <= self.hours_per_week <= 10:
            return "средняя"
        return "высокая"