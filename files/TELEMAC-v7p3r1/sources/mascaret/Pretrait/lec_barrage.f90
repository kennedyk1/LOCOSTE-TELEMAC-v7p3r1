!== Copyright (C) 2000-2017 EDF-CEREMA ==
!
!   This file is part of MASCARET.
!
!   MASCARET is free software: you can redistribute it and/or modify
!   it under the terms of the GNU General Public License as published by
!   the Free Software Foundation, either version 3 of the License, or
!   (at your option) any later version.
!
!   MASCARET is distributed in the hope that it will be useful,
!   but WITHOUT ANY WARRANTY; without even the implied warranty of
!   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!   GNU General Public License for more details.
!
!   You should have received a copy of the GNU General Public License
!   along with MASCARET.  If not, see <http://www.gnu.org/licenses/>
!

subroutine LEC_BARRAGE( &
     Barrage          , & ! Barrage
     Connect          , & ! Connectivite du reseau
     X                , & ! Tableau du maillage
     Profil           , & ! Profils geometriques
     ProfDebBief      , & ! Premiers profils des biefs
     ProfFinBief      , & ! Derniers profils des biefs
     AbscRelExtDebBief, & ! Abscisse de l'extremite debut du bief
     AbscRelExtFinBief, & ! Abscisse de l'extremite debut du bief
     UniteListing     , & ! Unite logique fichier listing
     document         , & ! Pointeur vers document XML
     Erreur             & ! Erreur
                      )

! *********************************************************************
! PROGICIEL : MASCARET         A. LEBOSSE
!                              S. MANDELKERN
!                              F. ZAOUI                      
!
! VERSION : 8.1.4                EDF-CEREMA
! *********************************************************************

   !========================= Declarations ===========================
   use M_PRECISION
   use M_BARRAGE_T           ! Type BARRAGE_T
   use M_CONNECT_T           ! Type CONNECT_T : connectivite du reseau
   use M_ERREUR_T            ! Type ERREUR_T
   use M_PROFIL_T            ! Type PROFIL_T
   use M_MESSAGE_C           ! Messages d'erreur
   use M_CONSTANTES_CALCUL_C ! Constantes num, phys et info
   use M_TRAITER_ERREUR_I    ! Traitement de l'errreur
   use M_ABS_ABS_S           ! Calcul de l'abscisse absolue
   use M_XINDIC_S            ! Calc de l'indice corresp a une absc
   use Fox_dom               ! parser XML Fortran

   implicit none

   ! Arguments
   type(BARRAGE_T)                   , intent(  out) :: Barrage
   type(CONNECT_T)                   , intent(in   ) :: Connect
   real(DOUBLE)      , dimension(:)  , intent(in   ) :: X
   type(PROFIL_T)    , dimension(:)  , intent(in   ) :: Profil
   integer           , dimension(:)  , intent(in   ) :: ProfDebBief
   integer           , dimension(:)  , intent(in   ) :: ProfFinBief
   real(DOUBLE)      , dimension(:)  , intent(in   ) :: AbscRelExtDebBief
   real(DOUBLE)      , dimension(:)  , intent(in   ) :: AbscRelExtFinBief
   integer                           , intent(in   ) :: UniteListing
   type(Node), pointer, intent(in)                   :: document
   ! Variables locales
   real(DOUBLE) :: abs_abs     ! abscisse absolue du barrage
   integer      :: num_branche ! numero de la branche
   !character(132) :: !arbredappel_old
   type(Node), pointer :: champ1,champ2,champ3
   ! Traitement des erreurs
   type(ERREUR_T), intent(inout) :: Erreur

   !========================= Instructions ===========================
   ! INITIALISATION
   ! --------------
   Erreur%Numero = 0
   !arbredappel_old = trim(!Erreur%arbredappel)
   !Erreur%arbredappel = trim(!Erreur%arbredappel)//'=>LEC_BARRAGE'

   ! Barrage
   !--------
   if (UniteListing >0) write(UniteListing,10000)
   champ1 => item(getElementsByTagname(document, "parametresSingularite"), 0)
   if(associated(champ1).eqv..false.) then
      print*,"Parse error => parametresSingularite"
      call xerror(Erreur)
      return
   endif
   champ2 => item(getElementsByTagname(champ1, "barragePrincipal"), 0)
   if(associated(champ2).eqv..false.) then
       Barrage%TypeRupture = TYPE_RUPTURE_PROGRESSIVE
   else
      champ3 => item(getElementsByTagname(champ2, "typeRupture"), 0)
      if(associated(champ3).eqv..false.) then
          print*,"Parse error => typeRupture"
          call xerror(Erreur)
          return
      endif
      call extractDataContent(champ3,Barrage%TypeRupture)
   endif
   if( Barrage%TypeRupture /= TYPE_RUPTURE_PROGRESSIVE .and. &
       Barrage%TypeRupture /= TYPE_RUPTURE_INSTANTANEE) then
      Erreur%Numero = 321
      Erreur%ft     = err_321
      Erreur%ft_c   = err_321c
      call TRAITER_ERREUR( Erreur , Barrage%TypeRupture )
      return
   end if

   if( Barrage%TypeRupture == TYPE_RUPTURE_PROGRESSIVE ) then
      if (UniteListing >0) write(UniteListing,10020) 'TYPE RUPTURE PROGRESSIVE'
   else
      if (UniteListing >0) write(UniteListing,10020) 'TYPE RUPTURE INSTANTANEE'
   endif

   if( Barrage%TypeRupture == TYPE_RUPTURE_PROGRESSIVE ) then
      Barrage%AbscisseRel = AbscRelExtDebBief(1)
      Barrage%CoteCrete   = -1
      Barrage%NumBranche  =  1
   else
      champ3 => item(getElementsByTagname(champ2, "numBranche"), 0)
      if(associated(champ3).eqv..false.) then
          print*,"Parse error => numBranche"
          call xerror(Erreur)
          return
      endif
      call extractDataContent(champ3,Barrage%NumBranche)
      champ3 => item(getElementsByTagname(champ2, "coteCrete"), 0)
      if(associated(champ3).eqv..false.) then
         print*,"Parse error => coteCrete"
         call xerror(Erreur)
         return
      endif
      call extractDataContent(champ3,Barrage%CoteCrete)
      champ3 => item(getElementsByTagname(champ2, "abscisse"), 0)
      if(associated(champ3).eqv..false.) then
         print*,"Parse error => abscisse"
         call xerror(Erreur)
         return
      endif
      call extractDataContent(champ3,Barrage%AbscisseRel)
   endif

   num_branche = Barrage%NumBranche
   if( Barrage%NumBranche < 1 .or. &
       Barrage%NumBranche > size(Connect%OrigineBief) ) then
      Erreur%Numero = 320
      Erreur%ft     = err_320
      Erreur%ft_c   = err_320c
      call TRAITER_ERREUR  (Erreur)
      return
   end if
   if( Barrage%AbscisseRel < AbscRelExtDebBief(num_branche) .or. &
       Barrage%AbscisseRel > AbscRelExtFinBief(num_branche) ) then
      Erreur%Numero   = 323
      Erreur%ft       = err_323
      Erreur%ft_c     = err_323c
      call TRAITER_ERREUR( Erreur , Barrage%AbscisseRel , num_branche )
      return
   endif
   if (UniteListing >0) write(UniteListing,10010) Barrage%NumBranche, Barrage%AbscisseRel

   !-----------------------------
   ! Calcul de l'abscisse absolue
   !-----------------------------
   abs_abs = ABS_ABS_S     ( &
       num_branche         , &
       Barrage%AbscisseRel , &
       Profil              , &
       ProfDebBief         , &
       ProfFinBief         , &
       Erreur                &
                               )
   if( Erreur%Numero /= 0 ) then
      return
   end if

   !----------------------------------------------
   ! Calcul de la section de calcul correspondante
   !----------------------------------------------
   call XINDIC_S( Barrage%Section , abs_abs , X , Erreur )
   if( Erreur%Numero /= 0 ) then
      return
   endif

   if( Barrage%TypeRupture == TYPE_RUPTURE_INSTANTANEE ) then
      if( Barrage%CoteCrete < 0._DOUBLE ) then
         Erreur%Numero = 322
         Erreur%ft     = err_322
         Erreur%ft_c   = err_322c
         call TRAITER_ERREUR( Erreur , Barrage%CoteCrete )
         return
      end if
   end if
   if (UniteListing >0) write(UniteListing,10030) Barrage%CoteCrete

   !Erreur%Arbredappel = !arbredappel_old

   return

   ! Formats
   10000 format (/,'BARRAGE PRINCIPAL',/, &
               &  '-----------------',/)
   10010 format ('Numero de branche : ',i5,' Abscisse relative : ',f12.3)
   10020 format ('Type de rupture   : ',A)
   10030 format ('Cote de rupture   : ',f12.3)

   contains
   
   subroutine xerror(Erreur)
       
       use M_MESSAGE_C
       use M_ERREUR_T            ! Type ERREUR_T
       
       type(ERREUR_T)                   , intent(inout) :: Erreur
       
       Erreur%Numero = 704
       Erreur%ft     = err_704
       Erreur%ft_c   = err_704c
       call TRAITER_ERREUR( Erreur )
       
       return
        
   end subroutine xerror      
   
  end subroutine LEC_BARRAGE