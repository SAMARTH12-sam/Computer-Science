 


import math

def calculator():
    print("Welcome to the  Calculator!")
    print("Available  operations : ")
    print("1.Addition")
    print("2.Subtraction")
    print("3.Multiplication")
    print("4.Division")
    print("5.Exponentiation (Power)")
    print("6.Square Root")
    print("7.Sine")
    print("8.Cosine")
    print("9.Tangent")
    print("10 Exit")

    while True:
        choice = input("\nEnter the number corresponding to your choice (1-10): ")

        if choice == '10':
            print("Thank you for using the calculator. ")
            break

        if choice in ['1', '2', '3', '4', '5']:
            num1 = float(input("Enter the first number: "))
            num2 = float(input("Enter the second number:"))
            
            if choice == '1':
                print(f"The result is: {num1 + num2}")
            elif choice == '2':
                print(f"The result is: {num1 - num2}")
            elif choice == '3':
                print(f"The result is: {num1 * num2}")
            elif choice == '4':
                if num2 != 0:
                    print(f"The result is: {num1 / num2}")
                else:
                    print("Error! .")
            elif choice == '5':
                print(f"The result is: {num1 ** num2}")

        elif choice == '6':
            num = float(input("Enter the number: "))
            if num >= 0:
                print(f"The square root of {num} is: {math.sqrt(num)}")
            else:
                print("Error!.")

        elif choice in ['7', '8', '9']:
            angle = float(input("Enter the angle in degrees: "))
            radians = math.radians(angle)
            if choice == '7':
                print(f"Sine({angle}°) = {math.sin(radians)}")
            elif choice == '8':
                print(f"Cosine({angle}°) = {math.cos(radians)}")
            elif choice == '9':
                print(f"Tangent({angle}°) = {math.tan(radians)}")

        else:
            print("Invalid!this input is not mentioned,Please reselect a valid operation.")

calculator()
