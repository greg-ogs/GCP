show_expected_result = False
show_hints = False

class Answer:
    def is_palindrome(teststr):
        teststr = ''.join(char.lower() for char in teststr if char.isalnum())
        return teststr == teststr[::-1]


def testing():
    # This is how your code will be called.
    # Your function should return whether a string is a palindrome.
    # The code will count the number of correct answers.
    total = 0
    test_words = ["Hello World!","Radar","Mama?","Madam, I'm Adam.",
                  "Race car!"]
    for word in test_words:
        total += Answer.is_palindrome(word)
    return total

if __name__ == "__main__":
    total =+ testing()
    print("Total correct answers: " + str(total))