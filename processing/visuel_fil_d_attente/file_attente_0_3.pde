void setup() {
  size (600,400); //taille de la fenêtre d'affichage
  strokeWeight(0);  
  dessinerRoute();
  draw();
}


void dessinerRoute() {
  //compteurs
  int z=0;
  int w=0;

  //dessin de la route
  rect(0,140,600,90);
  rect(250,0,90,600);

  //pointillés route horizontale
  int xa=0;
  int ya=185;
  int xb=10;
  int yb=185;
  while(z<100) {  
    strokeWeight(1); 
    line(xa,ya,xb,yb);
    xa=xb+10;
    xb=xa+10;
    z++;
    }  
  
  //pointillés route verticale
  int xc=295;
  int yc=0;
  int xd=295;
  int yd=10;
  while(w<100) {  
    strokeWeight(1); 
    line(xc,yc,xd,yd);
    yc=yd+10;
    yd=yc+10;
    w++;
    }
}
 
  
void draw() {
  frameRate(2); //fréquence du draw
  float[] tableau = {round(random(1)),round(random(1)),round(random(1)),round(random(1))};  //creation du tableau avec aléatoirement 1 ou 0

  //compteur + coordonnées des voitures
  int i=0;
  float x=350;
  float y=150;
  float largeur=20;
  float longueur=40;
  
  //couleurs
  color full = color(245,23,23); //si place full:rouge
  color empty = color(23,203,53); //si place empty:vert
  
  //dessin + remplissage couleur
  while(i<4) {  
    if(tableau[i]==0) {
      fill(empty);
      strokeWeight(1); 
      rect(x,y,longueur,largeur);
      i++;
      x=x+longueur;
      }
    else if(tableau[i]==1) {
      fill(full);
      strokeWeight(1); 
      rect(x,y,longueur,largeur);
      i++;
      x=x+longueur;
      }
  }
}
