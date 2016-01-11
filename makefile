.PHONY: clean

FFLAGS=-fPIC -fdefault-double-8 -fdefault-real-8 -fdefault-integer-8 -O

src/radau5.f:
	cd src && wget http://www.unige.ch/~hairer/prog/stiff/radau5.f

src/lapack.f:
	cd src && wget http://www.unige.ch/~hairer/prog/stiff/lapack.f

src/lapackc.f:
	cd src && wget http://www.unige.ch/~hairer/prog/stiff/lapackc.f

src/dclapack.f:
	cd src && wget http://www.unige.ch/~hairer/prog/stiff/dc_lapack.f

jradau5.so: obj/jradau5.o obj/radau5.o obj/lapack.o obj/lapackc.o obj/dc_lapack.o
	gfortran $(FFLAGS) -shared $^ -o $@

obj/jradau5.o: src/jradau5.f95
	gfortran $(FFLAGS) -c $^ -o $@

obj/radau5.o: src/radau5.f
	gfortran $(FFLAGS) -c $^ -o $@

obj/lapack.o: src/lapack.f
	gfortran $(FFLAGS) -c $^ -o $@

obj/lapackc.o: src/lapackc.f
	gfortran $(FFLAGS) -c $^ -o $@

obj/dc_lapack.o: src/dc_lapack.f
	gfortran $(FFLAGS) -c $^ -o $@

clean:
	rm -f obj/*

