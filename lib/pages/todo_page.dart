import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../providers/auth_provider.dart';
import 'signin_page.dart';
import 'modal_todo.dart';
import 'user_details_page.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  @override
  Widget build(BuildContext context) {
    print("In ToDo Page");
    Stream<User?> userStream = context.watch<UserAuthProvider>().userStream;
    Stream<QuerySnapshot> todosStream = context.watch<TodoListProvider>().todo;

    print(userStream);
    return StreamBuilder(
        stream: userStream,
        builder: (context, snapshot) {
          print("Todo User $snapshot");
          if (snapshot.hasError) {
            return Center(
              child: Text("Error encountered! ${snapshot.error}"),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            //why entering here when uStream has user?
            print("stuck here");
            print(snapshot);
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (!snapshot.hasData) {
            // if user is logged in, display the scaffold containing the streambuilder for the todos
            return const SignInPage();
          }
          print("signed in todopage");

          return displayScaffold(context, todosStream);
        });
  }

  Scaffold displayScaffold(context, todosStream) {
    print("in displayScaffold()");

    return Scaffold(
      drawer: drawer,
      appBar: AppBar(
        title: const Text("Todo"),
      ),
      body: StreamBuilder(
        stream: todosStream,
        builder: (context, AsyncSnapshot snapshot) {
          //Added AsyncSnapshot so no more docs error https://stackoverflow.com/questions/67840643/flutter-error-the-getter-docs-isnt-defined-for-the-type-object
          if (snapshot.hasError) {
            return Center(
              child: Text("Error encountered! ${snapshot.error}"),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text("No Todos Found"),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data?.docs.length,
            itemBuilder: ((context, index) {
              Todo todo = Todo.fromJson(
                  snapshot.data?.docs[index].data() as Map<String, dynamic>);
              todo.id = snapshot.data?.docs[index].id;
              return Dismissible(
                key: Key(todo.id.toString()),
                onDismissed: (direction) {
                  context.read<TodoListProvider>().deleteTodo(todo.title);

                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${todo.title} dismissed')));
                },
                background: Container(
                  color: Colors.red,
                  child: const Icon(Icons.delete),
                ),
                child: ListTile(
                  title: Text(todo.title),
                  leading: Checkbox(
                    value: todo.completed,
                    onChanged: (bool? value) {
                      context
                          .read<TodoListProvider>()
                          .toggleStatus(todo.id!, value!);
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => TodoModal(
                              type: 'Edit',
                              item: todo,
                            ),
                          );
                        },
                        icon: const Icon(Icons.create_outlined),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => TodoModal(
                              type: 'Delete',
                              item: todo,
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outlined),
                      )
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) => TodoModal(
              type: 'Add',
              item: null,
            ),
          );
        },
        child: const Icon(Icons.add_outlined),
      ),
    );
  }

  Drawer get drawer => Drawer(
          child: ListView(padding: EdgeInsets.zero, children: [
        const DrawerHeader(child: Text("Todo")),
        ListTile(
          title: const Text('Details'),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UserDetailsPage()));
          },
        ),
        ListTile(
          title: const Text('Todo List'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, "/");
          },
        ),
        ListTile(
          title: const Text('Logout'),
          onTap: () {
            context.read<UserAuthProvider>().signOut();
            Navigator.pop(context);
          },
        ),
      ]));
}
