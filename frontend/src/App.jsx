// App.jsx
import { useState } from "react";
import styled from "styled-components";
import "bootstrap/dist/css/bootstrap.min.css";
import { BrowserRouter, Routes, Route } from "react-router-dom";

import { AuthProvider } from "./AuthContext";
import AuthUpdater from "./AuthAdapter";

import Header from "./common/Header";
import Footer from "./common/Footer";
import Sidebar from "./common/Sidebar";
import NotFound from "./common/NotFound";

import Home from "./pages/Home";
import Login from "./pages/Login";
import Profile from "./pages/Profile";
import AuditLogs from "./pages/AuditLogs";

import Reports from "./pages/Reports";
import ReportExpiredBatches from "./pages/Reports/ExpiredBatches";
import ReportBatches from "./pages/Reports/Batches";
import ReportDocumentsByEmployee from "./pages/Reports/DocumentByEmployee";
import ReportEmployees from "./pages/Reports/ReportEmployees";
import ReportGrants from "./pages/Reports/Grants";
import ReportNoProducts from "./pages/Reports/NoProducts";
import ReportPermissions from "./pages/Reports/Permissions";
import ReportProductsLeft from "./pages/Reports/ProductsLeft";
import ReportSystemUsers from "./pages/Reports/SystemUsers";
import ReportTableActivity from "./pages/Reports/ReportTableActivity";
import ReportProducerStatistics from "./pages/Reports/ProducerSubjectStatistics";
import ReportTableActivityPerHour from "./pages/Reports/TablesActivityPerHout";
import ReportProductsLeftByBatch from "./pages/Reports/ProductsLeftByBatch";
import RolesPage from "./pages/Roles/RolesPage";
import SysUsersPage from "./pages/SysUsers/SysUsersPage";
import PositionsPage from "./pages/Positions/PositionsPage";
import EmployeesPage from "./pages/Employees/EmployeesPage";
import GendersPage from "./pages/Genders/GerndrsPage";
import AddressesPage from "./pages/Addresses/AddressesPage";
import ProductsPage from "./pages/Products/ProductsPage";
import ProductsCategoriesPage from "./pages/ProductCategories/ProductCategoriesPage";
import DocumentCategoriesPage from "./pages/DocumentCategories/DocumentCategoriesPage";
import ProducersPage from "./pages/Producers/ProducersPage";

export const ContentWrapper = styled.div.attrs({
  className: "content-wrapper"
})`
  margin-top: 80px;
  min-height: calc(100vh - 60px);
`;

export default function App() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const toggleSidebar = () => setSidebarOpen(!sidebarOpen);

  return (
    <AuthProvider>
      <BrowserRouter>
        <AuthUpdater />
        <Header onToggleSidebar={toggleSidebar} />
        <ContentWrapper>
          <Sidebar show={sidebarOpen} onHide={() => setSidebarOpen(false)} />
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="*" element={<NotFound />} />
            <Route path="/login" element={<Login />} />
            <Route path="/profile" element={<Profile />} />
            <Route path="/audit_log" element={<AuditLogs />} />
            <Route path="/report" element={<Reports />} />
            <Route path="/role" element={<RolesPage />} />
            <Route path="/sys_user" element={<SysUsersPage />} />
            <Route path="/position" element={<PositionsPage />} />
            <Route path="/employee" element={<EmployeesPage />} />
            <Route path="/gender" element={<GendersPage />} />
            <Route path="/address" element={<AddressesPage />} />
            <Route path="/product" element={<ProductsPage />} />
            <Route path="/product_category" element={<ProductsCategoriesPage />} />
            <Route path="/document_category" element={<DocumentCategoriesPage />} />
            <Route path="/producer" element={<ProducersPage />} />

            <Route path="/report/report_batches" element={<ReportBatches/>} />
            <Route path="/report/report_documents_by_employee" element={<ReportDocumentsByEmployee/>} />
            <Route path="/report/report_employees" element={<ReportEmployees/>} />
            <Route path="/report/report_expired_batches" element={<ReportExpiredBatches/>} />
            <Route path="/report/report_grants" element={<ReportGrants/>} />
            <Route path="/report/report_interface_grants" element={<ReportPermissions/>} />
            <Route path="/report/report_no_products" element={<ReportNoProducts/>} />
            <Route path="/report/report_producer_subject_statistics" element={<ReportProducerStatistics/>} />
            <Route path="/report/report_products_left" element={<ReportProductsLeft/>} />
            <Route path="/report/report_products_left_by_batch" element={<ReportProductsLeftByBatch/>} />
            <Route path="/report/report_system_users" element={<ReportSystemUsers/>} />
            <Route path="/report/report_tables_activity" element={<ReportTableActivity/>} />
            <Route path="/report/report_tables_activity_per_hour" element={<ReportTableActivityPerHour/>} />
            
          </Routes>
        </ContentWrapper>
        <Footer />
      </BrowserRouter>
    </AuthProvider>
  );
}
