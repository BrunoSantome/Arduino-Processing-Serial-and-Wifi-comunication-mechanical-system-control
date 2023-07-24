 //<>//

//Variable que importa la libreria de mqtt para Processing
import mqtt.*;
//Variable que importa la libreria para ciertos controles y botonoes
import controlP5.*;
//Variable que importa la libreria para el recuadro de la contraseña
import g4p_controls.*;

ControlP5 cp5;
ControlP5 cp6;


//////Variables para la contraseña////
GPassword pwd1; 
GLabel lblPwd;
GTabManager tt;
GButton btn;
GButton btn2;
GButton btn5;
String contentpwd;
int stateLED;
boolean CorrectPassword = false;
boolean WrongPassword = false;


//Cliente mqtt
MQTTClient client; 

//El logs, que tiene que ser mejorado
PrintWriter logFile; // crea un archivo donde escribir
int tab = 1;  //Esta variable puntea al tab que estamos usando

/////VARIABLES LUZ//////
int LightValue = 200; //Luz por defecto, este valor se actualizará una vez lleguen valores del arduino
int xLightDetections = 515;//Variable para la grafica lightDetectionGraph
ArrayList<PVector> lightDetections = new ArrayList();//Aqui vamos guardando los valores de luz
int valueCountedUp = 0; 


////Variables de Temperatura//////
int TempValue = 0;
float TemperatureValue;
//Si el arduino esta desconectado, la temperatura se queda en Null, este valor cambia una vez que recibimos cosas. 
String TemperatureString = "Null";

//Variables Booleanas importantes para las condiciones del funcionamiento de la interfaz////
boolean LED = false;
boolean password = false;
boolean EnoughLight = false;
boolean EnoughTemperature = false;


////Variable boolean de las distintas pestañas/////
boolean tab1 = false;
boolean tab2 = false;
boolean tab3 = false; 
boolean tab4 = false;


///////Variables Motor /////////
int SpeedValue;  //Valor de la velocidad
String SpeedValueS = "150"; // String del valor de la velocidad
String DireccionMotor;  
boolean motor = false;
boolean clockwise= true;
boolean anticlockwise=false;


//Diversos botones para la pestaña del controlador del motor
GButton btn3;
GButton btn4;
GButton btn6;
GButton btn7;
GButton btn8;

//Boton de ayuda.

GButton helpbtn;
boolean help = false;

//Variables tiempo de mensajes
int timeout = 5000; // 5 segundos de timeout
long lastMessageTime;
boolean Connected;


//Clase Adapter que implemente el Listener de Mqtt, para la escucha de mensajes recibidios a traves del broker.
class Adapter implements MQTTListener {
 
  
  void clientConnected() {
    println("client connected");
    //sucribirse a los canales necesarios
    client.subscribe("/arduino/Sensor/temperatura"); //Canal para recibir los valores de temperatura del arduino
    client.subscribe("/arduino/Sensor/Luz");         //Canal para recibir los valores de Luz del arduino
    //client.subscribe("/arduino/LED");                
    client.subscribe("/arduino/password/validation");//Canal para la validación de la contraseña
  }
  //Metodo que gestiona la recepción de mensajes
  void messageReceived(String topic, byte[] payload) {
    //Si recibimos un mensaje, asumimos que el arduino esta conectado. 
    
    Connected = true;
   
    String msg = new String(payload); //En esta variable se almacena el mensaje recibido
    lastMessageTime = millis(); //Igualamos el tiempo del último mensaje al de ahora. Puesto que habremos recibido otro. 
    //println("new message: " + topic + " valor:  " + msg); // Para ver el topic donde se ha recibido
    
    //Si el topic por el que se ha recibido el mensaje es el de Luz  ==> Obtenemos el valor de la luz pasando el String a integer. 
    if(topic.equals("/arduino/Sensor/Luz")){      
      LightValue = int(msg);

  }
    //Si el topic por el que se ha recibido el mensaje es el de temperatura
    if(topic.equals("/arduino/Sensor/temperatura")){
      //Almacenamos el dato en float, ya que el sensor transmite datos con dos decimales y se perdería precisión de información
      TemperatureValue =float(msg);
      TemperatureString = String.valueOf(msg);
      TempValue = (int) TemperatureValue;        //Tambien nos interesa el integer de la temperatura para poder comparar con los distintos Umbrales que le pongamos.
    }
    
    //Si el topic por el que se ha recibido el mensaje es el de validación de contraseña
    if(topic.equals("/arduino/password/validation")) {
      println("mensaje recibido del topic: /arduino/password/validation, con mensaje: "+msg);
      //Si el mensaje recibido es igual a "OK" ==> la contraseña es correcta. 
      if(msg.equals("OK")){
        println("contraseña correcta !");
        writeLog(logFile, "Contraseña correcta");
        CorrectPassword = true;
        WrongPassword = false;
      }
       //Si el mensaje recibido es igual a "wrong password" ==> la contraseña es Incorrecta. 
      if(msg.equals("wrong password")){
        println("contraseña incorrecta !");
        writeLog(logFile, "Contraseña incorrecta, intente de nuevo");
        WrongPassword = true;
        CorrectPassword = false;
      }
      
    }
  }
  //Función que llama la clase si pierde la conexión al router, es decir, a la conexión WIFI
  void connectionLost() {
    println("connection lost");
  }
}

//Creamos un objeto adapter
Adapter adapter;

void setup() {
  
  adapter = new Adapter();
  //Con el adapter creamos un objeto tipo client
  client = new MQTTClient(this, adapter);
  
  client.connect("mqtt://test.mosquitto.org", "processing"); // El cliente se conecta al broker, en este caso ambos, arduino y la interfaz usan mosquitto.org
  logFile = createWriter("logFile.txt"); //Creamos un archivo para escribir los logs
  size(800, 600); // Definimos el tamaño de la pestaña
  cp5 = new ControlP5(this); //Esto son los controladores de los umbrales ( cp5) y el controlador de la velocidad (cp6) 
  cp6 = new ControlP5(this);
  cp5.addSlider("UMBRAL luz").setPosition(400, 192).setSize(40, 130).setRange(0,1100);  
  cp5.addSlider("UMBRAL temp").setPosition(440,400).setSize(40,150).setRange(0,50);  
  cp6.addSlider("Valor velocidad").setPosition(140,240).setSize(220,40).setRange(150,255); 
  
  //Creación del recuadro de la contraseña
  tt = new GTabManager(); //El manager de el recuadro de la contraseña
  G4P.setInputFont("Times New Roman", G4P.PLAIN, 14);
  G4P.setCursor(ARROW);
  pwd1 = new GPassword(this, 70, 410 , 200, 20);    //Contraseña
  pwd1.tag = "pwd1";   
  pwd1.setMaxWordLength(20); //Maximo 20 palabras de input
  
  lblPwd = new GLabel(this, 70, pwd1.getY()-20, 200, 18);  //Posiciones concretas en pixeles donde se situa en la pestaña de 800x600 pixels
  lblPwd.setAlpha(190);
  lblPwd.setTextAlign(GAlign.LEFT, null);
  lblPwd.setOpaque(true);
  tt.addControls(pwd1); //Lo añadimos al manager. 
 
 
 
 //Serie de botones que aparecen durante toda la interfaz
  btn = new GButton(this, 70, 435, 100, 30, "Comprobar"); //Para comprobar la contraseña
  btn2 = new GButton(this,  70, 470, 200, 35, "Controlar Motor"); //Para controlar el motor
  btn3 =  new GButton(this,  520, 361, 40, 40, "ON");  //ON- ENCENDER MOTOR
  btn4 =  new GButton(this,  520, 446, 40, 40, "OFF"); //OFF - APAGAR MOTOR
  btn5 = new GButton(this,  60, 260, 45, 35, "LED3"); //APAGAR/ENCENDER LED1
  btn6 = new GButton(this,  140, 290,100, 35, "Ajustar Velocidad"); //Para enviar la contraseña deseada al motor del arduino
  btn7 = new GButton(this,  140, 450,100, 60, "Dirección AntiHoraria");  //Cambiar la dirección del motor a anti horario
  btn8 = new GButton(this,  300, 450,100, 60, "Dirección Horaria"); //Cambiar la dirección del motor a horario
  helpbtn = new GButton(this,  244, 555,80, 30, "AYUDA");
}

//Esta función comprueba que no se ha desconectado el arduino. 
//Lo hacemos mediante la recepción de mensajes. 
//Si vemos que no recibimos nada en 5 segundos, asumimos que el arduino esta desconectado
void checkTimeout() {
    if (millis() - lastMessageTime > timeout) {
        println("Arduino Disconnected");
        Connected = false;  
    }
  }

//Función principal para dibujar la interfaz, en esta se llaman a distintas funciones que hacen distintas partes de la interfaz. 
void draw() {

background(47,79,79);//establecer un color de fondo
PImage logo=loadImage("assets/logo.png"); //Logo de la interfaz, esta por cambiar 
image(logo,20,10,300,100); 
checkTimeout(); //Llamamos primero de todo a la función que comprueba que el arduino esta conectado. 



switch(tab){ //Switch para cambiar de pestañas en la interfaz, hay un total de 3 pestañas

  case 1: //Por defecto, siempre se inicia en la primera pestaña que es la de monitorización de sensores y contraseña
  tab1 = true; 
  tab2 = false;
  tab3 = false; 
  tab4 = false;
  
  showMonitorization();  //Función que se ocupa de diseñar la monitorización de los sensores y el control de las LEDS del arduino
  drawMenuMonitorizationSelected();  //Menu superior para la orientación entre las distintas pestañas
  ConexionArduino();    //Si el arduino esta conectado, aparecera un indicador en verde con su correspondiente estado escrito, sino el indicador sera rojo
  //Función deseada de la aplicación, si Hay suficiente nivel de oscuridad, suficiente nivel de temperatura y el arduino esta conectado, podremos poner una contraseña para acceder al motor
  
  
  if(Connected){
    helpbtn.setVisible(true);
  }else{
  helpbtn.setVisible(false);
  }
  if(EnoughLight && LED && EnoughTemperature &&Connected){ 
  passwordSection(); //Función que dibuja el recuadro de contraseña 
  pwd1.setVisible(true);
  btn.setVisible(true);
  btn3.setVisible(false);
  btn4.setVisible(false);
  btn6.setVisible(false);
  btn7.setVisible(false);
  btn8.setVisible(false);
  lblPwd.setVisible(true);
  //Se ocultan todos los botones que pertenezacan a otra pestaña como los botones del motor. 
  } else{
    
  pwd1.setVisible(false); //<>//
  btn.setVisible(false);
  lblPwd.setVisible(false);
  btn2.setVisible(false);
  btn3.setVisible(false);
  btn4.setVisible(false);
  btn6.setVisible(false);
  btn7.setVisible(false);
  btn8.setVisible(false);
  }
  //Solo si Hay suficiente nivel de oscuridad, suficiente nivel de temperatura, el arduino esta conectado y la contraseña es correcta
  //Se podra acceder a la configuración del motor
  if(EnoughLight && LED && EnoughTemperature &&Connected &&CorrectPassword){
    //Aparece el boton para acceder a la pestaña del motor
   btn2.setVisible(true);
  }if(EnoughLight && LED && EnoughTemperature &&Connected && WrongPassword){
   //En caso contrario no aparece
   btn2.setVisible(false);
  } 
  //Umbrales 
  cp5.show();
  //Speed Motor
  cp6.hide();
  
  passwordHandler(); //Un handler del input de la contraseña
  btn5.setVisible(true);
  break; 
  
  //Pestaña número 2 - LOGS
  case 2:
  tab1 = false; 
  tab2 = true;
  tab3 = false; 
  tab4 = false;
  drawMenuMonitorizationSelected(); //Que aparezca el menu
  //todo desaparece. 
  pwd1.setVisible(false);
  btn.setVisible(false);
  btn2.setVisible(false);
  lblPwd.setVisible(false);
  btn5.setVisible(false);
  btn3.setVisible(false);
  btn4.setVisible(false);
  btn6.setVisible(false);
  btn7.setVisible(false);
  btn8.setVisible(false);
  helpbtn.setVisible(false);
  cp5.hide();
  cp6.hide();
  drawLogs(); //Invoca a la función que se ocupa de dibujar los LOGS (INACABADA)
  ConexionArduino(); 
  break;
 
 //Pestaña número 3 - Controlador del motor
 case 3:
  tab1 = false; 
  tab2 = false;
  tab3 = true; 
  tab4 = false;
  drawMenuMonitorizationSelected(); //Menu
  ConexionArduino(); //Tambien nos interesa que aparezca el indicador de conexión
  controlMotor(); //Función que maneja el diseño de la pestaña de motor
  pwd1.setVisible(false);
  btn.setVisible(false);
  btn2.setVisible(false);
  btn3.setVisible(true);
  btn4.setVisible(true);
  btn6.setVisible(true);
  lblPwd.setVisible(false);
  btn5.setVisible(false);
  btn7.setVisible(true);
  btn8.setVisible(true);
  helpbtn.setVisible(false);
  cp5.hide(); //Umbrales
  cp6.show(); //Speed
 break;
 
 case 4:
 tab1 = false; 
  tab2 = false;
  tab3 = false; 
  tab4 = true;
  drawMenuMonitorizationSelected(); 

  showHelp();
  cp5.hide(); //Umbrales
  helpbtn.setVisible(false);
  pwd1.setVisible(false);
  btn.setVisible(false);
  btn2.setVisible(false);
  lblPwd.setVisible(false);
  btn5.setVisible(false);
  break;
    }
}


//Se puede cambiar manualmente entre las pestañas de Monitorización y la pestaña de LOGS
void keyPressed() {

  switch(key) {
  case '1':
     tab = 1;
    break;
  case '2': 
     tab = 2;
    break;
  
  }
}


//Dibuja el recuadro de la contraseña (no necesario función) 
void passwordSection(){
  
  noFill();
  stroke(255);
  strokeWeight(2);
  rect(20,350 , 300, 180);
  
   fill(47,79,79);
   strokeWeight(2);
   stroke(255);
   rect(40,335,120, 30);
   fill(255);
   textSize(20);
   text("Contraseña",56,355);
  
}

void showHelp(){
  textSize(25);
  fill(255,255,255);
  text("AYUDA: Control & Monitorización", 380, 50);
  PImage help=loadImage("assets/help.png");
  help.resize(850, 0);
  image(help,-30,120);
}

//Manager de la contraseña
void passwordManager(){
 //Si es correcta y esta conectado 
 if(CorrectPassword && Connected){
   
   //Salta un mensaje en verde diciendo que es correcta
    fill(124,252,0);
    strokeWeight(0);
    rect(180,435,90,25);
    fill(0,0,0); 
    textSize(16);
    text("Correcta",185 , 453);
    
  }
  //Si es incorrecta y el arduino esta conectado
  if(WrongPassword && Connected){
     
    //Salta un mensaje en rojo diciendo que es incorrecta
     fill(228,105,105);
     strokeWeight(0);
     rect(180,435,90,25);
     fill(0,0,0); 
     textSize(16);
     text("Incorrecta", 185, 453);
  }
}

//Diseño del indiicador
void ConexionArduino(){
  //Circulito en verde con mensaje "Connected" si el arduino esta conectado
  if(Connected){
     strokeWeight(0);
     textSize(14);
     text("Arduino conectado", 55, 575);
     fill(39,236,59);
     circle(40,570,15);
     
  //Circulito en rojo con mensaje "Arduino disconnected" si el arduino esta desconectado
  }else{
     strokeWeight(0);
     textSize(14);
     text("Arduino disconectado", 55, 575);
     fill(220,20,60);
     circle(40,570,15);
     tab = 1;
    
  }
  
  
}

//-----------------------------Monitorización---------------------------------
void showMonitorization(){
  int umbralDay = (int) cp5.getController("UMBRAL luz").getValue(); //Sacamos constantemente el valor del umbral de luz
  int umbralTEMP = (int) cp5.getController("UMBRAL temp").getValue(); //Sacamos  constantemente el valor del umbral de temperatura
      
      
      //Si el valor de luz es superior al umbral establecido y no hay suficiente luz, se enciende la Luz
      if(LightValue > umbralDay) {
        if(!EnoughLight){
          println("NIVEL DE LUZ AMBIENTE INSUFICIENTE, ENCENDIENDO LED ");
          EnoughLight = true;
          //Publicamos en el canal de LED1 el valor de "ON"
           println("publish on topic: /arduino/LED1, the following message: "+ "ON");
          client.publish("/arduino/LED1", "ON");
        }
       
      }
      //Si el valor de luz es inferior al umbral establecido, se apaga la Luz
      else if(LightValue < umbralDay){
        if(EnoughLight){
           println("NIVEL DE LUZ AMBIENTE SUFICIENTE, APAGANDO LED ");
           EnoughLight = false; 
            //Publicamos en el canal de LED1 el valor de "OFF"
           println("publish on topic: /arduino/LED1, the following message: "+ "OFF");
           client.publish("/arduino/LED1", "OFF");
        }
      }
      //Si la temperatura esta por encima del umbral establecido, se enciende la LED2  
      if(TempValue > umbralTEMP) {
        if(!EnoughTemperature){
          println("TEMPERATURA AMBIENTE INSUFICIENTE, ENCENDIENDO LED ");
          EnoughTemperature= true;
           //Publicamos en el canal de LED2 el valor de "ON"
          println("publish on topic: /arduino/LED2, the following message: "+ "ON");
          client.publish("/arduino/LED2", "ON");
        }
       
      }
      //Si la temperatura esta por debajo del umbral establecido, se apaga la LED2  
      else if(TempValue < umbralTEMP){
        if(EnoughTemperature){
           println("TEMPERATURA AMBIENTE SUFICIENTE, APAGANDO LED ");
           EnoughTemperature = false; 
            //Publicamos en el canal de LED2 el valor de "OFF"
            println("publish on topic: /arduino/LED2, the following message: "+ "OFF");
           client.publish("/arduino/LED2", "OFF");
        }
      }
  
  drawLightPanel(); //Función que se ocupa de dibujar los simbolos de las luces
  helpLightsMenu(); //Función que añade el recuadro y las letras ==> se pueden combinar ambas funciones
  drawLightDetectionGraph(240,umbralDay); //Función que dibuja la grafica de la detección de luz
  drawTemperatureSensorDetection(umbralTEMP);//Función que dibuja el medidor de temperatura
  if(EnoughLight && LED && EnoughTemperature){ //Si esta encendida la LED3 hay suficiente luz y suficiente temperatura
  passwordManager(); //Podemos ver el recuadro de la contraseña
  }
}


//Función que se ocupa de dibujar los simbolos de las luces
void drawLightPanel(){
  
  //Importamos imagenes de bombillas y creamos circulos para meterlas. 
  //Si se encienden las luces cambian a su correspondiente color
  if(EnoughLight && Connected){
    fill(255,255,0); // Amarillo
    strokeWeight(1);
  }if(!EnoughLight && Connected){
    fill(200,200,200);
    strokeWeight(0);
  }if(!Connected){
    fill(200,200,200);
    strokeWeight(0);
  }
  strokeWeight(1);
  PImage NivelLuzLED =loadImage("assets/bombi.png");
  circle(270, 225, 50);
  image(NivelLuzLED,246,200,50,50);
  
  if(EnoughTemperature && Connected){
    fill(42,19,249); // Azul
    strokeWeight(1);
  }if(!EnoughTemperature){
    fill(200,200,200);
    strokeWeight(0);
  }if(!Connected){
    fill(200,200,200);
    strokeWeight(0);
  }
  strokeWeight(1);
  PImage NivelHumedadLED =loadImage("assets/bombi.png");
  //rect(150, 290, 120, 50);
  circle(180, 225, 50);
  image(NivelHumedadLED,155,200,50,50);
   
  //Esta es la LED que encendemos manualmente
  if(LED){
    fill(39,236,59); //Verde
    strokeWeight(1);
  }if(!LED && Connected){
    fill(200,200,200);
    strokeWeight(0);
  }if (!Connected){
    fill(200,200,200);
    strokeWeight(0);
  }
  strokeWeight(1);
  PImage LEDsimbol =loadImage("assets/bombi.png");
  //rect(150, 380, 120, 50);
  circle(80, 225, 50);
  image(LEDsimbol,55,200,50,50);
}


//Menu de la interfaz, se va resaltando de color blanco cuando esta seleccionado
void drawMenuMonitorizationSelected(){
  textSize(19);
  if(tab1){
  fill(255,255,255);
  }else{
    fill(200,200,200);
  }
   text("1: Monitorización", 330, 100);
  if(tab2){
  fill(255,255,255);
  }else{
    fill(200,200,200);
  }
  text("2: Historial", 500, 100);
  if(tab3){
  fill(255,255,255);
  }else{
    fill(200,200,200);
  }
  text("Controlador Motor", 630, 100);
}

//Gestiona el input de la contraseña ==> se puede combinar con otra función
void passwordHandler(){   
  if(pwd1.getPassword().length() == 0)
      lblPwd.setText("Introduce contraseña");
    else
      lblPwd.setText(pwd1.getPassword());
}


//Función vacia necesaria para el funcionamiento del evento de la contraseña
public void handlePasswordEvents(GPassword pwordControl, GEvent event) {
  
}

//Función que es llamada cada vez que se pulsa un boton en la interfaz
void handleButtonEvents(GButton button, GEvent event) {
      
  //Si el boton es el de check de la contraseña enviamos por su correspondiente canal de teletmetria la contraseña puesta en el recuadro
  if (button == btn && event == GEvent.CLICKED) {
    contentpwd = pwd1.getPassword();
     writeLog(logFile,"Intento de acceso: "+"'"+ contentpwd+"'");
    println("publish on topic: /arduino/password, the following password attempt: " + contentpwd);
    client.publish("/arduino/password", contentpwd);
  }
  
  //Si pulsamos el boton de Controlar motor que aparece una vez que la contraseña es correcta, nos lleva a la pestaña 3
  if  (button == btn2 && event == GEvent.CLICKED) {
        writeLog(logFile,"Acceso a Control de motor validado");
        tab = 3; 
  }
  
  //Si pulsamos el boton ON del motor, envia un mensaje de ON al arduino por su correspondiente canal de telemetria
  if  (button == btn3 && event == GEvent.CLICKED) {
         if(!motor){
           writeLog(logFile, "MOTOR:   ON");
           motor = true;
           //clockwise=true;
           println("publish on topic: /arduino/Motor the following message:  ON");
           client.publish("/arduino/Motor", "ON");
         }
  }
  //Igual que arriba pero para apagar el motor en el boton "OFF"
  if  (button == btn4 && event == GEvent.CLICKED){
        if(motor == true){
           writeLog(logFile, "MOTOR:   OFF");
           motor = false;
             println("publish on topic: /arduino/Motor the following message:  OFF");
           client.publish("/arduino/Motor", "OFF");
         }  
  }
   //Si pulsamos el boton de la LED1 y esta apagado se enciende y viceversa
   if  (button == btn5 && event == GEvent.CLICKED) {
         if(LED == true){
           writeLog(logFile, "LED 3:   OFF");
           LED = false;
           println("publish on topic: /arduino/LED3, the following message: "+ "OFF");
           client.publish("/arduino/LED3", "OFF");
         } 
         else {
           writeLog(logFile, "LED 3:   ON");
           LED = true;
           println("publish on topic: /arduino/LED3, the following message: "+ "ON");
           client.publish("/arduino/LED3", "ON");
         }
  }
  //Si pulsamos el boton de enviar velocidad, pasamos a string el valor  y lo enviamos por su correspondiente canal
  if  (button == btn6 && event == GEvent.CLICKED) {
      if(Connected){
        //Enviar la velocidad introducida

        // println(SpeedValue);
         String msg1 = Integer.toString(SpeedValue);
         SpeedValueS = Integer.toString(SpeedValue);
         println("publish on topic: /arduino/Motor/speed, the following motor speed: "+ msg1);
         client.publish("/arduino/Motor/speed",msg1);
         writeLog(logFile, "VELOCIDAD AJUSTADA: "+msg1+" RPM");
      }
    
  }
  //Para cambiar la dirección del motor a dirección antiHorario
  if  (button == btn7 && event == GEvent.CLICKED) {
    if(Connected){

      clockwise = false;
      anticlockwise=true;
       writeLog(logFile, "DIRECCIÓN AJUSTADA: SENTIDO ANTIHORARIO");
       println("publish on topic: /arduino/Motor/direccion, the following motor direction:  AntiClockWise");
       client.publish("/arduino/Motor/direccion", "AntiClockWise");
    }
  }
  //Para cambiar la dirección del motor a dirección Horario
    if  (button == btn8 && event == GEvent.CLICKED) {
    if(Connected){
      clockwise = true;
      anticlockwise=false;
      writeLog(logFile, "DIRECCIÓN AJUSTADA: SENTIDO HORARIO");
      println("publish on topic: /arduino/Motor/direccion, the following motor direction:  ClockWise");
       client.publish("/arduino/Motor/direccion", "ClockWise");
      
    }
  }
  
   if  (button == helpbtn && event == GEvent.CLICKED) {
        tab = 4;
   }
}

//Función que dibuja el recuadro del control de LEDS ==> se puede combinar con otra. 
void helpLightsMenu(){
  textSize(19);
  fill(255,255,255);
  text("LED1", 255, 280);
  fill(255,255,255);
  text("LED2",160, 280);
  fill(255,255,255);

  
  noFill();
  stroke(255);
  strokeWeight(2);
  rect(20,160 , 300, 150);
  
   fill(47,79,79);
   strokeWeight(2);
   stroke(255);
   rect(40,140 , 120, 30);
   fill(255);
   text("LED Control",50,160);
  

}

//################################GRafica temperatura#########################################################


//Esta función controla el detector de temperatura y dibuja un rectangulo que se va llenando conforme la temperatura va aumentando. 
void drawTemperatureSensorDetection(int umbralTEMP){
  PImage TemperatureDetectionSymbol =loadImage("assets/temperatureSymbol.png");
  image(TemperatureDetectionSymbol,610,420,110,110);
  String s = TemperatureString + " ºC";  
  textSize(25);
  fill(0,0,0);
  text(s ,680,490);
  fill(25,25,112);
  //Dimensiones del rectangulo de la temperatura
  stroke(0, 0, 0);
  rect(565, 400, 50, 150);
  /*Draw rect for distance*/
  int rangeDistance = 150;
  // esta variable se usara para establecer lo que se llena dentro del rectangulo en función del valor.
  //No creo que haya que dividir por 150 ==> Ver
  int tempSize = (TempValue*(rangeDistance))/50;
  //int distanceLength = (distanceValue*(rangeDistance))/150;
  fill(228,105,105);
  //Rectangulo que se rellena 
  rect(565, 400+(rangeDistance-tempSize), 50, tempSize);
  
  //#####UMbral#####
  //EL Umbral lo tiene que poder mover el usuario como en la grafica de luz. 
  int temperatureLength = (TempValue*(rangeDistance))/70;
  //Definicion del umbral ==> la TemperaturaLimite es el umbral. 

  int limitTemperatureAdjusted = (umbralTEMP*(rangeDistance))/50;
  stroke(0,255,255);
  //BARRA DEL UMBRAL.
  strokeWeight(2);
  line(565, 400+(rangeDistance-limitTemperatureAdjusted), 615, 400+(rangeDistance-limitTemperatureAdjusted));
  noFill();
  stroke(255);
  strokeWeight(2);
  rect(380,360 , 400, 220);
  
  
  //Recuadro del control de temperatura
   fill(47,79,78);
   strokeWeight(2);
   stroke(255);
   rect(400,348,210, 30);
   fill(255);
   textSize(20);
   text("Control Temperatura",417,370);
 
}

//################################GRafica Luz#########################################################
//Esta función dibuja la grafica de detección de luz
void drawLightDetectionGraph(int xLength, int umbralDay){
  
  
  noFill();
  stroke(255);
  strokeWeight(2);
  rect(380,160 , 400, 180);
   fill(47,79,78);
   strokeWeight(2);
   stroke(255);
   rect(400,135, 190, 30);
   fill(255);
   text("Control Luz Ambiente",415,157);
  fill(25,25,112);
  strokeWeight(0);
  rect(515,190,240,130);
  textSize(9);
  fill(255,255,255);
  text("1100", 517, 200); 
  fill(255,255,255);
  text("0", 517, 315);
  textSize(10);
  fill(255,255,255);
  text("Oscuridad", 470, 200);
  fill(255,255,255);
  text("t(s)", 740, 335);
  //draw umbral lines
  stroke(0);
  strokeWeight(1);
  int umbralDayAdjusted = (((1100-umbralDay)*(320-190))/1100)+190; 
  stroke(170, 170, 170);
  line(515, umbralDayAdjusted, 515+240, umbralDayAdjusted);
 
    
  if(xLightDetections > 515+xLength){        /*
    Esta línea comprueba si la posición horizontal actual de las detecciones de luz, representada por la variable "xLightDetections", 
    supera el límite del gráfico establecido por "515 + xLength". Si es así, la variable se reinicia a 515, lo que permite que las nuevas detecciones de 
    luz se muestren al comienzo del gráfico.

    */
    xLightDetections = 515;
  
    
    
  }
  xLightDetections++;//Step para obtener el siguiente valor
  int lightValueAdjusted = (((1100-LightValue)*(320-190))/1100)+190; // ajustamos la cordenada y del Pvector
  lightDetections.add(new PVector(xLightDetections,lightValueAdjusted));//añadimos el valor al array
  if( lightDetections.size() > 50 ) lightDetections.remove(0);//Quitamos el valor más antiguo
  for( int i = 0; i<lightDetections.size()-1; i++){  // Este bucle for itera a través de las detecciones de luz almacenadas en el array "light
    stroke(map(i,0,lightDetections.size()-1,0,255));
    strokeWeight(1);
    if( lightDetections.get(i).x < lightDetections.get(i+1).x) 
    line(lightDetections.get(i).x,lightDetections.get(i).y, lightDetections.get(i+1).x,lightDetections.get(i+1).y);
  }
  textSize(9);
  fill(255,255,0);
  text(LightValue, lightDetections.get(lightDetections.size()-1).x, lightDetections.get(lightDetections.size()-1).y); //El número concreto de luz que acompaña a la linea de luz
 
}
//Function Description: Escribe un mensjae en un archivo
//FUNCION NO ACABADA ==> CAMBIAR
void writeLog(PrintWriter file, String message){
   file.print("["+day()+"/"+month()+"/"+year()+"||"+hour( )+":"+minute( )+":"+second( )+"]    =====>   "+message+"\n");
   file.flush();
}

//DIbuja los LOGS de la interfaz
//FUNCION NO ACABADA ==> CAMBIAR
void drawLogs() {
  // Construir el rectángulo negro para los registros
  fill(25, 25, 25); // Color de relleno: negro
  stroke(100, 100, 100); // Color del borde: gris oscuro
  strokeWeight(3);
  rect(150, 150, 500, 400);

  // Obtener las últimas líneas
  ArrayList<String> lines = parseFile("logFile.txt");
  int logLimit = 30;
  textSize(14);
  fill(200, 200, 200); // Color del texto: blanco
  int yLogPosition = 170;
  int xLogPosition = 160;

  for (int i = lines.size() - 1, logCount = 0; i >= 0 && logCount < logLimit; i--) {
    text(lines.get(i), xLogPosition, yLogPosition);
    yLogPosition += 13;
    logCount++;
  }
}


//Continuamente guardamos los logs en un archivo que se crea externo a la app. 
ArrayList<String> parseFile(String fileName){
  BufferedReader reader = createReader(fileName);//Open the file
  String line = null;
  ArrayList<String> result = new ArrayList<String>();
  
  try {
    while ((line = reader.readLine()) != null) {
      result.add(line);
    }
    reader.close();
  } catch (IOException e) {
    e.printStackTrace();
  }
  return result;
}




//----------------------------------Motor-------------------------------------------------

//
void controlMotor(){
  //cogemos el valor de velocidad que el usuario desea para enviarlo al arduino
  SpeedValue = (int) cp6.getController("Valor velocidad").getValue();
  
  //Imagen del motor
  PImage MotorDC =loadImage("assets/large.png");
  image(MotorDC,500,200,150,130);
  
  
  //Recuadro de control de motor
   noFill();
  stroke(255);
  strokeWeight(3);
  rect(80,160 , 640, 380);
  
   fill(47,79,79);
   strokeWeight(3);
   stroke(255);
   rect(140,140, 150, 30);
   fill(255);
   textSize(20);
   text("Control Motor",155,160);
   
  
  //Indicadores de encender/ apagar el motor 
   if(motor && Connected){
   fill(50,205,50); //VERDE
    strokeWeight(1);
  }if(!motor&& Connected){
    fill(200,200,200); //Gris
    strokeWeight(0);
  }if(!Connected){
    fill(200,200,200);
    strokeWeight(0);
  }
  strokeWeight(1);
  PImage MotorON =loadImage("assets/bombi.png");
  circle(625, 380, 50);
  image(MotorON,600,355,50,50);
  
  if(motor && Connected){
   fill(200,200,200); 
    strokeWeight(1);
  }if(!motor&& Connected){
    fill(255,0,0);//VERDE
    strokeWeight(0);
  }if(!Connected){
    fill(200,200,200);
    strokeWeight(0);
  }
  strokeWeight(1);
  PImage MotorOFF =loadImage("assets/bombi.png");
  circle(625, 460, 50);
  image(MotorOFF,600,435,50,50);
  
  // clockwise = true;
  //    anticlockwise=false;
  fill(200,200,200);
  if(anticlockwise && Connected){
   fill(51,51,255); //Azul
    strokeWeight(1);
  }if(clockwise && Connected){
    fill(200,200,200);//gris
    strokeWeight(0);
  }if(!Connected){
    fill(200,200,200);
    strokeWeight(0);
  }
  strokeWeight(1);
  PImage Right =loadImage("assets/bombi.png");
  circle(185, 415, 50);
  image(Right,160,390,50,50);
  
   fill(200,200,200);
   if(clockwise && Connected){
   fill(255,153,51); //naranja
    strokeWeight(1);
  }if(anticlockwise && Connected){
    fill(200,200,200);//gris
    strokeWeight(0);
  }if(!Connected){
    fill(200,200,200);
    strokeWeight(0);
  }
  strokeWeight(1);
  PImage Left =loadImage("assets/bombi.png");
  circle(340, 415, 50);
  image(Left,315,390,50,50);
   

  textSize(20);
  fill(255,255,255);
  String string = "Velocidad ajustada actual: "+SpeedValueS + " RPM";
  text(string,140,350);
}
