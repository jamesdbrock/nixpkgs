{ lib
, stdenv
, fetchPypi
, buildPythonPackage
, which
, pkg-config
, python
, isPy27
, doxygen
, cairo
, ncurses
, pango
, wxGTK
, pillow
, numpy
, attrdict
, sip
, libXinerama
, libSM
, libXxf86vm
, libXtst
, libGLU
, libGL
, xorgproto
, gst_all_1
, libglvnd
, mesa
, webkitgtk
, autoPatchelfHook
, pythonOlder
}:
let
  dynamic-linker = stdenv.cc.bintools.dynamicLinker;
in
buildPythonPackage rec {
  pname = "wxPython";
  version = "4.2.0";
  disabled = pythonOlder "3.10";

  src = fetchPypi {
    inherit pname version;
    sha256 = "663cebc4509d7e5d113518865fe274f77f95434c5d57bc386ed58d65ceed86c7";
  };

  # https://github.com/NixOS/nixpkgs/issues/75759
  # https://github.com/wxWidgets/Phoenix/issues/1316
  doCheck = false;

  nativeBuildInputs = [
    which
    doxygen
    wxGTK.gtk
    pkg-config
  ] ++ lib.optionals stdenv.isLinux [
    autoPatchelfHook
    sip
  ];

  buildInputs = [
    wxGTK.gtk
    ncurses
  ] ++ lib.optionals stdenv.isLinux [
    libXinerama
    libSM
    libXxf86vm
    libXtst
    xorgproto
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    libGLU
    libGL
    libglvnd
    mesa
    webkitgtk
  ];

  propagatedBuildInputs = [ pillow numpy attrdict ];

  DOXYGEN = "${doxygen}/bin/doxygen";

  preConfigure = lib.optionalString (!stdenv.isDarwin) ''
    substituteInPlace wx/lib/wxcairo/wx_pycairo.py \
      --replace '_dlls = dict()' '_dlls = {k: ctypes.CDLL(v) for k, v in [
        ("gdk",        "${wxGTK.gtk}/lib/libgtk-x11-3.0.so"),
        ("pangocairo", "${pango.out}/lib/libpangocairo-1.0.so"),
        ("cairoLib = None", "cairoLib = ctypes.CDLL('${cairo}/lib/libcairo.so')"),
        ("appsvc",     None)
      ]}'
  '';

  buildPhase = ''
    ${python.interpreter} build.py -v build_wx dox etg --nodoc sip build_py
  '';

  installPhase = ''
    ${python.interpreter} setup.py install --skip-build --prefix=$out
    wrapPythonPrograms
  '';

  meta = with lib; {
    broken = stdenv.isDarwin;
    description = "Cross platform GUI toolkit for Python, Phoenix version";
    homepage = "http://wxpython.org/";
    license = licenses.wxWindows;
    maintainers = with maintainers; [ tfmoraes ];
  };
}
