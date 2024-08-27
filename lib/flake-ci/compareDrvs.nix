let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
  joinAttrsets = prev: next: lib.attrsets.recursiveUpdate prev next;
  isAdded = as: (as ? prev) == false && (as ? next) == true;
  isRemoved = as: (as ? prev) == true && (as ? next) == false;
  isUpdated = as: (as.prev or "") != (as.next or as.prev);
  mapUpdateFlags = as: builtins.mapAttrs (k: v: v // { added = isAdded v; removed = isRemoved v; updated = isUpdated v; }) as;
  checkNeedsRefresh = as: builtins.any (k: as.${k}.added || as.${k}.updated) (builtins.attrNames as);
  mapRefreshFlag = as: as // { needsRefresh = (checkNeedsRefresh as); };
in
prev: next:
mapRefreshFlag (mapUpdateFlags (joinAttrsets prev next))
