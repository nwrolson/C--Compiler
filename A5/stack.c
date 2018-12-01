#include "stack.h"

void push(int i){
    stack[top] = i;
    i++;
}

int peek() {
    return stack[i];
}

int pop() {
    int out = stack[i];
    i--;
    return out;
}
