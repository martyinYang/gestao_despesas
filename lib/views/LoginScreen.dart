import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestao_despesas/views/CadastroUsuario.dart';
import 'package:gestao_despesas/views/Home.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _senhaController.text,
      );

      if (userCredential.user != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Home())); 
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Usuário ou senha incorretos')));
    }
  }

   void _navegarParaCadastro() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CadastroUsuario(), 
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: _senhaController,
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            SizedBox(height: 16),
             Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Entrar'),
                ),
                SizedBox(height: 16), //tive que usar n sei o que ta acontecendo
                ElevatedButton(
                  onPressed: _navegarParaCadastro,
                  child: Text('Cadastrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
