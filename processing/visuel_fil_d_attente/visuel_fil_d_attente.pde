size (600,400); //taille de la fenêtre d'affichage
strokeWeight(0); 

boolean[] tableau = {true,true,false,false};  //creation du tableau

//compteurs
int i=0;
int z=0;
int w=0;

//couleurs
color full = color(245,23,23); //si place full:rouge
color empty = color(23,203,53); //si place empty:vert

float x=350;
float y=150;
float largeur=20;
float longueur=40;

//dessin de la route
rect(0,140,600,90);
rect(250,0,90,600);

//coordonnées route
int xa=0;
int ya=185;
int xb=10;
int yb=185;
int xc=295;
int yc=0;
int xd=295;
int yd=10;


//pointillés route horizontale
while(z<100) {  
strokeWeight(1); 
line(xa,ya,xb,yb);
xa=xb+10;
xb=xa+10;
z++;
}


//pointillés route verticale
while(w<100) {  
  strokeWeight(1); 
  line(xc,yc,xd,yd);
  yc=yd+10;
  yd=yc+10;
  w++;
}


//dessin file d'attente
while(i<4) {  

    if(tableau[i]==false) {
      fill(empty);
      strokeWeight(1); 
      rect(x,y,longueur,largeur);
      i++;
      x=x+longueur;}
    else {
      fill(full);
      strokeWeight(1); 
      rect(x,y,longueur,largeur);
      i++;
      x=x+longueur;
    }
}

