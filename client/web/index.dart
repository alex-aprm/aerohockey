import 'dart:html';
void main() {
  document.body.children.clear();
  document.body.append(new HeadingElement.h1()..text = 'Hello world');
}