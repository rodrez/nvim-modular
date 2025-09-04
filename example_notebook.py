# %% Example Jupyter-style notebook in Neovim
# This file demonstrates the inline Jupyter functionality

# %% Basic output
print("Hello from Neovim Jupyter!")
x = 42
print(f"The answer is {x}")

# %% Mathematical computation
import math
from time import sleep

def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

print("Fibonacci sequence:")
for i in range(11):
    result = fibonacci(i)
    print(f"F({i}) = {result}")
    sleep(1)

print(f"\nThe 10th Fibonacci number is: {fibonacci(10)}")

# %% Data visualization (requires matplotlib)
# Uncomment the following lines if you have matplotlib installed:
# import matplotlib.pyplot as plt
# import numpy as np
# 
# x = np.linspace(0, 2*np.pi, 100)
# y = np.sin(x)
# 
# plt.figure(figsize=(10, 6))
# plt.plot(x, y, 'b-', linewidth=2, label='sin(x)')
# plt.xlabel('x')
# plt.ylabel('sin(x)')
# plt.title('Sine Wave')
# plt.legend()
# plt.grid(True)
# plt.show()

# %% Error handling example
# This cell will produce an error to demonstrate error display
# Uncomment the next line to see error handling:
# undefined_variable + 5

# %% List comprehension
numbers = [1, 2, 3, 4, 5]
squares = [x**2 for x in numbers]
print(f"Numbers: {numbers}")
print(f"Squares: {squares}")

# %% End of notebook
