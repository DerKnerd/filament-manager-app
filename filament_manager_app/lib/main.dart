import 'package:filament_manager_app/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:postgres/postgres.dart';

void main() {
  runApp(const FilamentManagerApp());
}

class FilamentManagerApp extends StatelessWidget {
  const FilamentManagerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filament Manager',
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      home: const FilamentList(),
    );
  }
}

class FilamentSpool {
  double initialWeight = 0;
  double usedWeight = 0;
  String name = '';
  double cost;

  FilamentSpool(this.initialWeight, this.usedWeight, this.name, this.cost);
}

class FilamentProfile {
  int id;
  String vendor;
  String material;
  double density;
  double diameter;

  FilamentProfile(this.id, this.vendor, this.material, this.density, this.diameter);
}

class ServerSettings {
  final String server;
  final int port;
  final String username;
  final String password;
  final String database;

  ServerSettings(this.server, this.port, this.username, this.password, this.database);
}

class ServerSettingsDialog extends StatefulWidget {
  final String server;
  final int port;
  final String username;
  final String password;
  final String database;

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState(
        this.server,
        this.port,
        this.username,
        this.password,
        this.database,
      );

  ServerSettingsDialog(this.server, this.port, this.username, this.password, this.database, {super.key});
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  final String server;
  final int port;
  final String username;
  final String password;
  final String database;

  var usernameController = TextEditingController();
  var passwordController = TextEditingController();
  var databaseController = TextEditingController();
  var serverController = TextEditingController();
  var portController = TextEditingController();

  _ServerSettingsDialogState(this.server, this.port, this.username, this.password, this.database) {
    serverController.text = server;
    portController.text = port.toString();
    usernameController.text = username;
    passwordController.text = password;
    databaseController.text = database;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Server ändern'),
      content: Scrollbar(
        child: Form(
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Server'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: serverController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Port'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: portController,
                enableSuggestions: false,
                keyboardType: TextInputType.number,
                maxLength: 5,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Datenbankname'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: databaseController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Benutzername'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: usernameController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: passwordController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(
              ServerSettings(
                serverController.text,
                int.parse(portController.text, radix: 10),
                usernameController.text,
                passwordController.text,
                databaseController.text,
              ),
            );
          },
          child: const Text('Verbindung speichern'),
        ),
      ],
    );
  }
}

class AddSpoolDialog extends StatefulWidget {
  const AddSpoolDialog(this.serverSettings, {super.key});

  final ServerSettings serverSettings;

  @override
  State<AddSpoolDialog> createState() => _AddSpoolDialogState(serverSettings);
}

class _AddSpoolDialogState extends State<AddSpoolDialog> {
  final ServerSettings serverSettings;
  Iterable<FilamentProfile> profiles = [];
  var weightController = TextEditingController();
  var nameController = TextEditingController();
  var costController = TextEditingController();
  FilamentProfile? profile;

  _AddSpoolDialogState(this.serverSettings);

  Future<void> loadProfiles() async {
    final conn = PostgreSQLConnection(serverSettings.server, serverSettings.port, serverSettings.database,
        username: serverSettings.username, password: serverSettings.password);
    await conn.open();

    try {
      List<Map<String, Map<String, dynamic>>> results = await conn.mappedResultsQuery(
          'SELECT profiles.id, profiles.vendor, profiles.material, profiles.density, profiles.diameter FROM profiles ORDER BY vendor');
      setState(() {
        profiles = results.map((e) {
          return FilamentProfile(
            e['profiles']?['id'],
            e['profiles']?['vendor'],
            e['profiles']?['material'],
            e['profiles']?['density'],
            e['profiles']?['diameter'],
          );
        });
        profile = profiles.first;
      });
    } finally {
      await conn.close();
    }
  }

  @override
  void initState() {
    super.initState();
    loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return AlertDialog(
      scrollable: true,
      title: const Text('Spule hinzufügen'),
      content: Scrollbar(
        child: Form(
          child: Column(
            children: [
              DropdownButtonFormField(
                items: profiles.map((e) {
                  return DropdownMenuItem(
                    child: Text('${e.vendor}(${e.material})'),
                    value: e.id,
                  );
                }).toList(),
                onChanged: (value) => profile = profiles.firstWhere((element) => element.id == value),
                decoration: const InputDecoration(labelText: 'Hersteller und Material'),
                value: profile?.id,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: nameController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Preis in €'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: costController,
                enableSuggestions: false,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Gewicht in g'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: weightController,
                enableSuggestions: false,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () async {
            final conn = PostgreSQLConnection(serverSettings.server, serverSettings.port, serverSettings.database,
                username: serverSettings.username, password: serverSettings.password);
            await conn.open();

            try {
              await conn.execute(
                'INSERT INTO spools (profile_id, name, cost, weight) VALUES (@profileId, @name, @cost, @weight)',
                substitutionValues: {
                  'profileId': profile?.id,
                  'name': nameController.text,
                  'cost': double.parse(costController.text),
                  'weight': double.parse(weightController.text)
                },
              );
              navigator.pop();
            } finally {
              await conn.close();
            }
          },
          child: const Text('Spule hinzufügen'),
        ),
      ],
    );
  }
}

class EditSpoolDialog extends StatefulWidget {
  const EditSpoolDialog(this.serverSettings, this.spool, {super.key});

  final ServerSettings serverSettings;
  final FilamentSpool spool;

  @override
  State<EditSpoolDialog> createState() => _EditSpoolDialogState(serverSettings, spool);
}

class _EditSpoolDialogState extends State<EditSpoolDialog> {
  final ServerSettings serverSettings;
  final FilamentSpool spool;
  var initialWeightController = TextEditingController();
  var usedWeightController = TextEditingController();
  var nameController = TextEditingController();
  var costController = TextEditingController();

  _EditSpoolDialogState(this.serverSettings, this.spool) {
    initialWeightController.text = spool.initialWeight.toStringAsFixed(2);
    usedWeightController.text = spool.usedWeight.toStringAsFixed(2);
    nameController.text = spool.name;
    costController.text = spool.cost.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return AlertDialog(
      scrollable: true,
      title: const Text('Spule bearbeiten'),
      content: Scrollbar(
        child: Form(
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: nameController,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Preis in €'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: costController,
                enableSuggestions: false,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Ursprungsgewicht in g'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: initialWeightController,
                enableSuggestions: false,
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Verbrauchtes Gewicht in g'),
                autocorrect: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: usedWeightController,
                enableSuggestions: false,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text('Änderungen verwerfen'),
        ),
        TextButton(
          onPressed: () async {
            final conn = PostgreSQLConnection(serverSettings.server, serverSettings.port, serverSettings.database,
                username: serverSettings.username, password: serverSettings.password);
            await conn.open();

            try {
              await conn.execute(
                'UPDATE spools SET name=@name, cost=@cost, weight=@initialWeight, used=@usedWeight WHERE name = @oldName',
                substitutionValues: {
                  'name': nameController.text,
                  'oldName': spool.name,
                  'cost': double.parse(costController.text),
                  'initialWeight': double.parse(initialWeightController.text),
                  'usedWeight': double.parse(usedWeightController.text),
                },
              );
              navigator.pop();
            } finally {
              await conn.close();
            }
          },
          child: const Text('Spule speichern'),
        ),
      ],
    );
  }
}

class FilamentList extends StatefulWidget {
  const FilamentList({Key? key}) : super(key: key);

  @override
  State<FilamentList> createState() => _FilamentListState();
}

class _FilamentListState extends State<FilamentList> {
  var server = '192.168.2.219';
  var port = 5432;
  var username = 'printer';
  var password = 'printer';
  var database = 'printer';

  Iterable<FilamentSpool> spools = [];

  Future<void> deleteSpool(FilamentSpool spool) async {
    final conn = PostgreSQLConnection(server, port, database, username: username, password: password);
    await conn.open();

    try {
      await conn.execute('DELETE FROM spools WHERE name = @name', substitutionValues: {'name': spool.name});
      await loadData();
    } finally {
      await conn.close();
    }
  }

  Future<void> loadData() async {
    final conn = PostgreSQLConnection(server, port, database, username: username, password: password);
    await conn.open();

    try {
      List<Map<String, Map<String, dynamic>>> results = await conn
          .mappedResultsQuery('SELECT spools.name, spools.weight, spools.used, spools.cost FROM spools ORDER BY name');
      setState(() {
        spools = results.map((e) {
          return FilamentSpool(
              e['spools']?['weight'] ?? 0, e['spools']?['used'] ?? 0, e['spools']?['name'] ?? '', e['spools']?['cost']);
        });
      });
    } finally {
      await conn.close();
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: const Text('Filament Manager'),
        actions: [
          IconButton(
            onPressed: () async {
              final dialog = ServerSettingsDialog(server, port, username, password, database);
              ServerSettings? result = await showDialog(context: context, builder: (context) => dialog);
              if (result != null) {
                server = result.server;
                port = result.port;
                username = result.username;
                password = result.password;
                database = result.database;

                await loadData();
              }
            },
            icon: const Icon(MdiIcons.databaseEdit),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadData();
        },
        child: ListView.builder(
          itemBuilder: (context, index) {
            final spool = spools.elementAt(index);
            return Dismissible(
              key: Key(spool.name),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).errorColor,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
              ),
              onDismissed: (direction) {
                deleteSpool(spool);
                setState(() {
                  spools = spools.where((element) => element.name != spool.name);
                });
              },
              child: ListTile(
                isThreeLine: true,
                title: Text(spool.name),
                subtitle: Text(
                    '${(spool.initialWeight - spool.usedWeight).toStringAsFixed(2)}g übrig\nKosten: ${spool.cost.toStringAsFixed(2)} €'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final dialog = EditSpoolDialog(ServerSettings(server, port, username, password, database), spool);
                    await showDialog(
                      context: context,
                      builder: (context) => dialog,
                    );
                    await loadData();
                  },
                ),
              ),
            );
          },
          itemCount: spools.length,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final dialog = AddSpoolDialog(ServerSettings(server, port, username, password, database));
          await showDialog(
            context: context,
            builder: (context) => dialog,
          );
          await loadData();
        },
      ),
    );
  }
}
