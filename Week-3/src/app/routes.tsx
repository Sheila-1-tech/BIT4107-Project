import { createBrowserRouter } from "react-router";
import { LoginScreen } from "./screens/LoginScreen";
import { HomeScreen } from "./screens/HomeScreen";
import { MedicineDetailsScreen } from "./screens/MedicineDetailsScreen";
import { PrescriptionUploadScreen } from "./screens/PrescriptionUploadScreen";
import { ProfileScreen } from "./screens/ProfileScreen";
import { WireframesScreen } from "./screens/WireframesScreen";
import { CartScreen } from "./screens/CartScreen";

export const router = createBrowserRouter([
  { path: "/", Component: LoginScreen },
  { path: "/home", Component: HomeScreen },
  { path: "/medicine/:id", Component: MedicineDetailsScreen },
  { path: "/prescription", Component: PrescriptionUploadScreen },
  { path: "/profile", Component: ProfileScreen },
  { path: "/wireframes", Component: WireframesScreen },
  { path: "/cart", Component: CartScreen },
]);
