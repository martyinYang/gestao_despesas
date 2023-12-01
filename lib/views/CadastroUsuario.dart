import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestao_despesas/views/LoginScreen.dart';

class CadastroUsuario extends StatefulWidget {
  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();
}

class _CadastroUsuarioState extends State<CadastroUsuario> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmaSenhaController =
      TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    super.dispose();
  }

  void limpaCampos() {
    _emailController.clear();
    _nomeController.clear();
    _senhaController.clear();
    _confirmaSenhaController.clear();
  }

  void _navegarParaLogin() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => LoginScreen(),
    ));
  }

  Future<void> _cadastrarUsuario() async {
    if (_senhaController.text == _confirmaSenhaController.text) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _senhaController.text,
        );
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user?.uid)
            .set({
          'nome': _nomeController.text,
        });

        if (userCredential.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Usuario registrado com sucesso')));
          _navegarParaLogin();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Falha ao registrar o usuário.')));
        }
        limpaCampos();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('A senha fornecida é muito fraca.')));
        } else if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Já existe uma conta com este e-mail.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao registrar o usuário.')));
        limpaCampos();
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('As senhas não coincidem')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Usuário'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
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
            TextFormField(
              controller: _confirmaSenhaController,
              decoration: InputDecoration(labelText: 'Confirme a Senha'),
              obscureText: true,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _cadastrarUsuario,
                  child: Text('Cadastrar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => LoginScreen()));
                  },
                  child: Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
