import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class Todo {
  String? id;
  String? job;
  String? details;
  bool? done;

  Todo({
    this.id,
    this.job,
    this.details,
    this.done,});

  Todo.fromDocumentSnapshot({DocumentSnapshot? documentSnapshot}) {
    if (documentSnapshot!.data()!=null) {
      id=documentSnapshot.id;
      job=(documentSnapshot.data() as Map<String, dynamic>)['job'] as String;
      details=(documentSnapshot.data() as Map<String, dynamic>)['details'] as String;
      done=(documentSnapshot.data() as Map<String, dynamic>)['done'] as bool;
    }
    else {
      id='';
      job='';
      details='';
      done=false;
    }
  }

}

class Auth {
  final FirebaseAuth auth;

  Auth({required this.auth});

  Stream<User?> get user=>auth.authStateChanges();

  Future<String?> createAccount({String? email, String? password}) async {
    try {
      await auth.createUserWithEmailAndPassword(email: email!.trim(), password: password!.trim());
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
    catch (e) {
      rethrow;
    }
  }

  Future<String?> signIn({String? email, String? password}) async {
    try {
      await auth.signInWithEmailAndPassword(email: email!.trim(), password: password!.trim());
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
    catch (e) {
      rethrow;
    }
  }

  Future<String?> signOut() async {
    try {
      await auth.signOut();
      return 'Success';
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
    catch (e) {
      rethrow;
    }
  }
}

class Database {
  final FirebaseFirestore firestore;

  Database({required this.firestore});

  Stream<List<Todo>> streamTodos({required String uid}) {
    try {
      return firestore
          .collection('todos')
          .doc(uid)
          .collection('todos')
          .where('done', isEqualTo: false)
          .snapshots()
          .map((QuerySnapshot q) {
            final List<Todo> retVal=[];
            q.docs.forEach((element) {
              retVal.add(Todo.fromDocumentSnapshot(documentSnapshot: element));
            });
            return retVal;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTodo({String? Email, String? job, String? details}) async {
    try {
      firestore
      .collection('todos')
      .doc(Email)
      .collection('todos')
      .doc()
      .set({'job':job, 'details':details, 'done':false});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTodo({String? Email, String? id}) async {
    try {
      firestore
          .collection('todos')
          .doc(Email)
          .collection('todos')
          .doc(id)
          .update({'done':true});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTodo({String? Email, String? id}) async {
    try {
      firestore
          .collection('todos')
          .doc(Email)
          .collection('todos')
          .doc(id)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error'),
              ),
            );
          }
          if (snapshot.connectionState==ConnectionState.done) {
            return First();
          }
          return Scaffold(
            body: Center(
              child: Text('Loading...'),
            ),
          );
        },
      ),
    );
  }
}

class First extends StatefulWidget {
  const First({Key? key}) : super(key: key);

  @override
  State<First> createState() => _FirstState();
}

class _FirstState extends State<First> {

  final FirebaseAuth _auth=FirebaseAuth.instance;
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth(auth: _auth).user,
      builder: (context, snapshot) {
        if (snapshot.connectionState==ConnectionState.active) {
          if (snapshot.data?.email==null) {
            return Login(auth:_auth, firestore: _firestore);
          }
          else
            return Home(auth:_auth, firestore: _firestore);
        }
        else {
          return Scaffold(
            body: Center(
              child: Text('Loading...'),
            ),
          );
        }
      });
  }
}

class Login extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  const Login({Key? key,
               required this.auth,
               required this.firestore}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final _emailController=TextEditingController();
  final _passwordController=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Builder(
             builder: (context) {
               return Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   TextFormField(
                     textAlign: TextAlign.center,
                     decoration: InputDecoration(hintText: 'Email'),
                     controller: _emailController,
                   ),
                   TextFormField(
                     textAlign: TextAlign.center,
                     decoration: InputDecoration(hintText: 'Password'),
                     controller: _passwordController,
                   ),
                   SizedBox(height: 20,),
                   ElevatedButton(
                       onPressed: () async {
                         final String? retVal=await Auth(auth: widget.auth).signIn(
                           email:_emailController.text,
                           password: _passwordController.text,
                         );
                         if (retVal=='Success') {
                           _emailController.clear();
                           _passwordController.clear();
                         }
                         else {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(retVal!)));
                         }
                       },
                       child: Text('Sign In'),
                   ),
                   ElevatedButton(
                     onPressed: () async {
                       final String? retVal=await Auth(auth: widget.auth).createAccount(
                         email:_emailController.text,
                         password: _passwordController.text,
                       );
                       if (retVal=='Success') {
                         _emailController.clear();
                         _passwordController.clear();
                       }
                       else {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(retVal!)));
                       }
                     },
                     child: Text('Create Account'),
                   ),
                 ],
               );
             },
          ),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  const Home({Key? key,
              required this.auth,
              required this.firestore}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _todoController1=TextEditingController();
  final _todoController2=TextEditingController();
  String email_account='';

  @override
  void initState() {
    super.initState();
    email_account=widget.auth.currentUser!.email!.split('@')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo App v1'),
        actions: [
          IconButton(
              onPressed: () {
                Auth(auth: widget.auth).signOut();
              },
              icon: Icon(Icons.exit_to_app)),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20,),
          Text('Add todo job here', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
          Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(child: TextFormField(controller: _todoController1,)),
                  IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        if (_todoController1.text.isNotEmpty) {
                          setState(() {
                            Database(firestore: widget.firestore).addTodo(Email: widget.auth.currentUser!.email,
                                                                          job: _todoController1.text.trim(),
                                                                          details: _todoController2.text.trim(),);
                            _todoController1.clear();
                            _todoController2.clear();
                          });
                        }
                      }),
                ],
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(child: TextFormField(controller: _todoController2,)),
                  IconButton(
                      icon: Icon(Icons.note_alt_outlined),
                      onPressed: () {}),
                ],
              ),
            ),
          ),
          SizedBox(height: 20,),
          Text('Your todos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
          Expanded(
            child: StreamBuilder(
               stream: widget.firestore.collection('todos').doc(widget.auth.currentUser!.email).collection('todos').where('done', isEqualTo: false).snapshots(),
               builder: (context, snapshot) {
                 if (snapshot.connectionState==ConnectionState.active) {
                   if (snapshot.data!.docs.isEmpty) {
                     return Center(
                     child: Text("You don't have any unfinished todos"),
                     );
                   }
                   final List<Todo> retVal=[];
                   snapshot.data!.docs.forEach((element) {
                     retVal.add(Todo.fromDocumentSnapshot(documentSnapshot: element));
                   });
                   return ListView.builder(
                     itemCount: snapshot.data!.docs.length,
                     itemBuilder: (context, index) {
                       return TodoCard(
                          firestore: widget.firestore,
                          email: widget.auth.currentUser!.email!,
                          todo: retVal[index],
                       );
                     });
                 }
                 else {
                   return Center(child: Text('Loading...'),);
                 }
            },
          ),),
        ],
      ),
    );
  }
}

class TodoCard extends StatefulWidget {
  final FirebaseFirestore firestore;
  final String email;
  final Todo todo;

  const TodoCard({Key? key,
                  required this.todo,
                  required this.firestore,
                  required this.email}) : super(key: key);

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: ListTile(
          title: Text(widget.todo.job!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
          subtitle: Text(widget.todo.details!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
          trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                Database(firestore: widget.firestore).updateTodo(Email: widget.email,
                                                                 id: widget.todo.id);
              }),
        ),
      ),
    );
  }
}
