/*
 * (C) Copyright 2017-2018 UCAR
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 */

#include "ObsSeaIceThickness.h"

#include <ostream>
#include <string>

#include <boost/scoped_ptr.hpp>

#include "eckit/config/Configuration.h"
#include "oops/base/Variables.h"
#include "ufo/ObsOperatorBase.h"
#include "ioda/ObsSpace.h"
#include "ufo/GeoVaLs.h"
#include "ufo/ObsBias.h"
#include "ufo/ObsBiasIncrement.h"
#include "ioda/ObsVector.h"
#include "oops/util/ObjectCounter.h"

namespace ufo {

// -----------------------------------------------------------------------------
static ObsOperatorMaker<ObsSeaIceThickness> makerSeaIceThickness_("SeaIceThickness");
// -----------------------------------------------------------------------------

ObsSeaIceThickness::ObsSeaIceThickness(const ioda::ObsSpace & odb, const eckit::Configuration & config)
  : keyOperSeaIceThickness_(0), varin_(), odb_(odb)
{
  const eckit::Configuration * configc = &config;
  ufo_seaicethick_setup_f90(keyOperSeaIceThickness_, &configc);
  const std::vector<std::string> vv{"ice_concentration", "ice_thickness"};
  varin_.reset(new oops::Variables(vv));
  oops::Log::trace() << "ObsSeaIceThickness created." << std::endl;
}

// -----------------------------------------------------------------------------

ObsSeaIceThickness::~ObsSeaIceThickness() {
  ufo_seaicethick_delete_f90(keyOperSeaIceThickness_);
  oops::Log::trace() << "ObsSeaIceThickness destructed" << std::endl;
}

// -----------------------------------------------------------------------------

void ObsSeaIceThickness::simulateObs(const GeoVaLs & gom, ioda::ObsVector & ovec,
                             const ObsBias & bias) const {
  ufo_seaicethick_eqv_f90(keyOperSeaIceThickness_, gom.toFortran(), odb_.toFortran(), ovec.toFortran(), bias.toFortran());
}

// -----------------------------------------------------------------------------

void ObsSeaIceThickness::print(std::ostream & os) const {
  os << "ObsSeaIceThickness::print not implemented";
}

// -----------------------------------------------------------------------------

}  // namespace ufo
