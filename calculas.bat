@echo off
setlocal enabledelayedexpansion

set /p func=Enter function f(x): 

echo import sympy as sp > calc.py
echo import matplotlib.pyplot as plt >> calc.py
echo x = sp.symbols('x') >> calc.py
echo f = %func% >> calc.py
echo fprime = sp.diff(f, x) >> calc.py
echo fint = sp.integrate(f, x) >> calc.py

echo sp.plot(f, (x,-5,5), show=True) >> calc.py
echo sp.plot(fprime, (x,-5,5), show=True) >> calc.py
echo sp.plot(fint, (x,-5,5), show=True) >> calc.py

python calc.py

pause