import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:line_icons/line_icons.dart';
import 'package:mobile_inventory_system/API%20Response/api_response.dart';
import 'package:mobile_inventory_system/admin/purchase_order_view.dart';
import 'package:mobile_inventory_system/admin/stocks_data.dart';
import 'package:mobile_inventory_system/constants/constants.dart';
import 'package:mobile_inventory_system/login/login.dart';
import 'package:mobile_inventory_system/pages/super_admin.dart';
import '../admin/admin_instance.dart';
import '../custom_widget/admin_custom.dart';
import '../users/user_instance.dart';
class Admin extends StatefulWidget {
  const Admin({ Key? key }) : super(key: key);

  @override
  _AdminState createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  Future<Dashboard> refreshData(BuildContext context)async{
    return fetchDashboard();
  }
  
  Future<Dashboard> fetchDashboard()async{
    final response = await http.get(Uri.parse(dashboardUrl));

    if(response.statusCode == 200){
      return Dashboard.fromJson(jsonDecode(response.body));
    }else{
      throw Exception('Failed');
    }
  }

  Future<Map<String,dynamic>> fetchUserOnly()async{
    String token = await getToken();
    final response = await http.get(
      Uri.parse(userUrl),
      headers: {
        'Authorization' : 'Bearer $token'
      }
    );

    if(response.statusCode == 200){
      final Map<String, dynamic> data = json.decode(response.body);
      return data['user'];
    }else{
      throw Exception('Error');
    }
  }

  void logout()async{
    String token = await getToken();
    final response = await http.post(Uri.parse(logoutUrl), 
    headers: {
      'Authorization' : 'Bearer $token'
    });
    if(response.statusCode == 200){
       await removeRole();
       await logOutRemoveToken();
    }
    print(response.statusCode);
  }

  void removeTokenRole()async{
    removeRole();
    await logOutRemoveToken();
    
  }

  //late Future<Dashboard> futureDashboard;
  @override
  void initState() {
    super.initState();
    fetchDashboard();
    fetchUserOnly();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: fetchUserOnly(),
            builder: (BuildContext context, snapshot){
              if(snapshot.connectionState == ConnectionState.done){
                if(snapshot.hasError){
                  return const Text('Error');
                }else if(snapshot.hasData){
                  final data = snapshot.data!;
                  //return Text('${data['name']}');
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(width: 1, color: Colors.black),
                          image: const DecorationImage(
                            image: AssetImage('assets/User.jpg'),
                            fit: BoxFit.cover
                          )
                        )
                      ),
                      const SizedBox(height: 30),
                      Text('Name: ${data['name']}', style: GoogleFonts.poppins(fontSize: 20)),
                      const SizedBox(height: 5),
                      Text('Email: ${data['email']}', style: GoogleFonts.poppins(fontSize: 18)),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: ()async{
                          removeTokenRole();
                          Navigator.push(context, MaterialPageRoute(builder: (context)=> const Login()));
                        },
                        child: Container(
                          height: 50,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Row(
                            children: const [
                              SizedBox(width: 15),
                              Icon(LineIcons.alternateSignOut),
                              SizedBox(width: 5),
                              Text('Log Out')
                            ],
                          ),
                        ),
                      ),
                      
                    ],
                  );
                }
              }else if(snapshot.hasError){
                return Text('${snapshot.error}');
              }else{
                return const CircularProgressIndicator();
              }
              return const CircularProgressIndicator();
            }),
        ),
      ),
      appBar: AppBar(
        //automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        title: Text('Administrator', style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white54,
      ),
      body: Center(
        child: FutureBuilder<Dashboard>(
          future: fetchDashboard(),
          builder: (BuildContext context,snapshot){
            if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      Visibility(
                        visible: snapshot.hasData,
                        child: const Text(
                          'Loading',
                          style: TextStyle(color: Colors.black, fontSize: 24),
                        ),
                      )
                    ],
                  );
                } else if(snapshot.connectionState == ConnectionState.done){
                  if (snapshot.hasError) {
                    return const Text('Error');
                  } else if (snapshot.hasData) {
                    return Column(
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Text("DASHBOARD", style: GoogleFonts.poppins(
                              fontSize: 30
                            )),
                            const SizedBox(height: 50),
                            Row(
                              children: [
                                const SizedBox(width: 30),
                                GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const StocksData()));
                                  },
                                  child: DashboardCards(
                                    color: Colors.orange[400], 
                                    icon: LineIcons.wineGlass, 
                                    textData: '${snapshot.data!.products_quantity} pcs',
                                    cardTitle: 'Liquor Quantity',
                                  )
                                ),
                                const SizedBox(width: 35),
                                DashboardCards(
                                  icon: LineIcons.fileInvoiceWithUsDollar, 
                                  textData: '${snapshot.data!.inventory_value} PHP', 
                                  color: Colors.blue[200], 
                                  cardTitle: 'Inventory Value')
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 30),
                                DashboardCards(
                                  icon: LineIcons.userFriends, 
                                  textData: '${snapshot.data!.admin_count}', 
                                  color: Colors.orange[200], 
                                  cardTitle: 'Customer'
                                ),
                                const SizedBox(width: 35),
                                GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const PurchaseOrderView()));
                                  },
                                  child: DashboardCards(
                                    icon: LineIcons.barChartAlt, 
                                    textData: '${snapshot.data!.orders_value} PHP', 
                                    color: Colors.blue[200], 
                                    cardTitle: 'Sales')
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 40),
                        Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 30),
                                DashboardCards(
                                  icon: LineIcons.shoppingBag, 
                                  textData: '${snapshot.data!.product_count} pcs', 
                                  color: Colors.orange[200], 
                                  cardTitle: 'Products')
                                //const SizedBox(width: 35)
                              ],
                            )
                          ],
                        )
                      ],
                    );
                  } else {
                    return const Text('Empty data');
                  }
                }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}